# coding: utf-8
#!/usr/bin/python3

import os

import nltk
import spacy

# model_path = '/home/en_model'
nlp = spacy.load("en_core_web_sm")

import csv
import json
import re
import types
import urllib.request
from urllib.parse import quote

import acadnomClass.langmodel as langmodel
import numpy as np
import torch
from nltk.corpus import wordnet
from spacy.symbols import advmod, root

CatvarNomlexLee = []
with open("Dicts/CatvarNomlexLee.csv", newline="") as csvfile:
    wordlistreader = csv.reader(csvfile, delimiter=";", quotechar='"')
    for row in wordlistreader:
        res = row[0], row[1], row[2], row[3], row[4], row[5], row[6]
        CatvarNomlexLee.append(res)

englishPastParticiples = []
with open("Dicts/EnglishPartPatriciples.csv", newline="") as csvfile:
    partpreader = csv.reader(csvfile, delimiter=";", quotechar='"')
    for row in partpreader:
        res = row[0], row[1], row[2]
        englishPastParticiples.append(res)

antonymData = []
with open("Dicts/Negation_vanSonDirect_AinSimpDouble.csv", newline="") as csvfile:
    wordlistreader = csv.reader(csvfile, delimiter=";", quotechar='"')
    for row in wordlistreader:
        res = row[0], row[1], row[2]
        antonymData.append(res)

catvardicts = []
with open("Dicts/cleaned_LispDataDict.txt", "r") as inf:
    for line in inf:
        catvardicts.append(eval(line))

adv2adjBank = []
with open("Dicts/adv2adj.csv", newline="") as csvfile:
    wordlistreader = csv.reader(csvfile, delimiter=";", quotechar='"')
    for row in wordlistreader:
        res = row[0], row[1]
        adv2adjBank.append(res)


def bert_mask_predict(sent):
    tokens = ["[CLS]"] + sent.split() + ["[SEP]"]
    mask_index = tokens.index("[MASK]")
    indices = [i for i, val in enumerate(tokens) if val == "[MASK]"]
    results = []
    for index in indices:
        sentence = " ".join(tokens)
        input_ids = torch.tensor(langmodel.bert_tokenizer.encode(sentence)).unsqueeze(0)
        outputs = langmodel.bert_model(input_ids, masked_lm_labels=input_ids)
        pre = outputs[1].topk(50)
        words = pre[1]
        best_words = words[0][index]
        scores = pre[0]
        best_scores = scores[0][index]
        predictions = [
            langmodel.bert_tokenizer.convert_ids_to_tokens(x.tolist())
            for x in best_words
        ]
        res = zip(predictions, [x.item() for x in best_scores])
        results.append([(x[0], round(x[1], 2))[0:5] for x in res])
    return results


class Expression:

    engPOSPR = {
        "my": "i",
        "your": "you",
        "his": "he",
        "her": "she",
        "its": "it",
        "our": "we",
        "their": "they",
    }

    def __init__(self, part, time):

        self.result = []
        self.part = part
        self.time = time

        self.sentMTX = sentMatrix(self.part)
        self.rootIndex = self.sentMTX[1].tolist().index("ROOT")
        self.root = self.sentMTX[0].tolist()[self.rootIndex]
        self.subjPRdep = self.sentMTX[1].tolist()[0]
        self.subjPRword = self.sentMTX[0].tolist()[0]
        self.subjPRpos = self.sentMTX[1].tolist()[0]
        self.subjPRtag = self.sentMTX[3].tolist()[0]
        self.verb = None
        self.adject = None
        self.remain = None
        self.subject = None
        self.object = None
        self.res = None

        # processes
        self.rootCheck()
        self.remained()
        self.p2p()
        self.expressTime()
        self.passiveConverter()
        self.clauseMaker()

        # result
        self.cleaned()

    def result(self):
        return self.result[0]

    def cleaned(self):
        # if self.result:
        sent = self.result[0]
        sent = sent.replace("None", "")
        sent = sent.strip()
        sent = re.sub(" +", " ", sent)
        return sent

    def passiveConverter(self):
        # pass
        # If system determines that the clause has been probably a passive sentence, we will
        # need to replace the verb
        if self.verb and not self.active and self.time == "past" and not self.plural:
            self.verbPast = "was {}".format(self.verbPast)
        elif self.verb and not self.active and self.time == "past" and self.plural:
            self.verbPast = "were {}".format(self.verbPast)
        elif (
            self.verb and not self.active and self.time == "present" and not self.plural
        ):
            self.verbPast = "is {}".format(self.verbPast)
        elif self.verb and not self.active and self.time == "present" and self.plural:
            self.verbPast = "are {}".format(self.verbPast)

    def clauseMaker(self):
        res = ""
        # self.plural,self.subCase,self.verb,self.verbPast,self.verbPresent,self.verbThirdP
        if self.verb and self.time == "past":
            res = "{} {} {} {}".format(
                str(self.subject),
                str(self.verbPast),
                str(self.object),
                str(self.remain),
            )
            self.result.append(res)
            print("1", res)
        elif self.verb and not self.plural and self.time == "present":
            res = "{} {} {}".format(
                str(self.subject),
                str(self.verbThirdP),
                str(self.object),
                str(self.remain),
            )
            self.result.append(res)
            print("2", res)
        elif self.verb and self.plural and self.time == "present":
            res = "{} {} {}".format(
                str(self.subject),
                str(self.verbPresent),
                str(self.object),
                str(self.remain),
            )
            self.result.append(res)
            print("3", res)

        elif (
            self.adject
            and self.subCase == 1
            and not self.plural
            and self.time == "past"
        ):
            res = "{} was {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("4", res)
        elif self.adject and self.subCase == 1 and self.plural and self.time == "past":
            res = "{} were {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("5", res)

        elif (
            self.adject
            and self.subCase == 1
            and not self.plural
            and self.time == "present"
        ):
            res = "{} is {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("6", res)
        elif (
            self.adject and self.subCase == 1 and self.plural and self.time == "present"
        ):
            res = "{} are {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("7", res)
        elif self.adject and self.subCase == 2 and self.plural and self.time == "past":
            res = "{} were {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("8", res)
        elif (
            self.adject
            and self.subCase == 2
            and not self.plural
            and self.time == "past"
        ):
            res = "{} was {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("9", res)
        elif (
            self.adject and self.subCase == 2 and self.plural and self.time == "present"
        ):
            res = "{} are {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("10", res)
        elif (
            self.adject
            and self.subCase == 2
            and not self.plural
            and self.time == "present"
        ):
            res = "{} is {} {}".format(
                str(self.subject), str(self.adject), str(self.remain)
            )
            self.result.append(res)
            print("11", res)
        return res

    def expressTime(self):

        # check if our subject is pronoun or not and singular or not
        if self.subCase == 1 and self.subject in ["we", "you", "they"]:
            self.plural = True
        elif self.subCase == 1 and self.subject not in ["we", "you", "they"]:
            self.plural = False
        elif self.subCase == 2:
            self.plural = False  # we need to determine subject plurality here

        # Preparing the Past tenses for all our verbs

        engVerbs = [x[0] for x in englishPastParticiples]

        if self.verb and self.verb in engVerbs:
            self.verbPast = [
                (x[0], x[1]) for x in englishPastParticiples if x[0] == self.verb
            ]
            self.verbPast = self.verbPast[0][1]
            self.verbPresent = self.verbPast[0][0]
            self.verbThirdP = self.verbPresent + "s"
            if self.verb.endswith("e"):
                self.verbPast = self.verb + "d"
            elif self.verb.endswith("e"):
                self.verbPast = self.verb + "ed"
        else:
            if not self.adject:
                if self.verb.endswith("e"):
                    self.verbPresent = self.verb
                    self.verbPast = self.verb + "d"
                    self.verbThirdP = self.verb + "s"
                else:
                    self.verbPresent = self.verb
                    self.verbPast = self.verb + "ed"
                    self.verbThirdP = self.verb + "s"
            else:
                self.verb = None  # we need to determine subject plurality here

        # print(self.plural,self.subCase,self.verb,self.verbPast,self.verbPresent,self.verbThirdP)

    def remained(self):
        self.remain = None
        if self.rootIndex:
            self.remain = self.sentMTX[0].tolist()[self.rootIndex + 1 :]

        # remove the first of from remaining part
        if " ".join(self.remain).startswith("of"):
            self.remain = self.remain[1:]

        # We check if "as" or "by" is after verb such as
        #'her appointment by x' or 'her appointment as x'
        if "by" in self.remain:
            byIndex = self.remain.index("by")
            afterBy = self.remain[byIndex:]
            afterByNP = NpExtractNumpy(" ".join(afterBy), "NOUN")
            self.passSubject = afterByNP
            self.object = self.subjPRword
            self.active = False
            # self.object = " ".join(self.remain[self.rootIndex:byIndex])
        elif "as" in self.remain:
            byIndex = self.remain.index("as")
            afterBy = self.remain[byIndex:]
            afterByNP = NpExtractNumpy(" ".join(afterBy), "NOUN")
            self.passSubject = afterByNP
            self.object = self.subjPRword
            self.active = False
            # self.object = " ".join(self.remain[self.rootIndex:byIndex])
        else:
            self.active = True
            self.remain = " ".join(self.remain)

    def p2p(self):
        if self.subjPRdep == "poss" and self.subjPRtag == "PRP$":
            a = Expression.engPOSPR.get(self.subjPRword)
            self.subject = a
            self.subCase = 1
        else:
            self.subject = NpExtractNumpy(self.part, "NOUN")
            self.subject = self.subject.replace(self.root, "")
            self.subject = self.subject.replace("'s", "")
            self.subCase = 2

    def rootCheck(self):
        self.verb_check = self.n2v()
        if self.verb_check and self.verb_check[0] == "v":
            self.verb = self.verb_check[1]
            self.adject = None
        elif self.verb_check and self.verb_check[0] == "a":
            self.verb = None
            self.adject = self.verb_check[1]
        else:
            return None

    def n2v(self):
        myword = self.root
        result = []
        if type(myword) is list:
            for x in myword[0]:
                for entry in CatvarNomlexLee:
                    if myword in entry:
                        result.append((entry[0], entry[1]))
        else:
            for entry in CatvarNomlexLee:
                if myword in entry:
                    result.append((entry[0], entry[1]))

        if type(myword) is list and len(result) >= 2:
            res1 = " and ".join(result)
        elif len(result) >= 1:
            res1 = result[0]
        else:
            res1 = None
        return res1


class Clause:
    vagueStop = [
        "about",
        "kind of",
        "something",
        "somehow",
        "and that kind of thing",
        "what do you call it",
        "that stuff",
        "the thing",
        "whatyamacallhim",
        "sort of",
        "kind of",
        "in or around",
        "more or less",
        "four-ish",
        "and things like that",
        "and that kind of thing",
        "and stuff like that",
        "and that sort of thing and stuff",
        "and that type of thing and so on",
        "and things like that and this",
        "that and the other",
        "and the like" "whatever",
        "whoever",
        "whenever",
        "whichever",
    ]

    modalStop = [
        "can",
        "cannot",
        "could",
        "couldn't",
        "may",
        "might",
        "must",
        "shall",
        "should",
        "shouldn't",
        "would",
        "wouldn't",
        "ought",
    ]

    engSUBPR = [
        "i",
        "you",
        "he",
        "she",
        "it",
        "we",
        "they",
        "that",
        "this",
        "these",
        "those",
    ]
    engObjPronouns = ["me", "you", "him", "her", "it", "us", "you", "them"]
    engPOSPR = {
        "i": "my",
        "you": "your",
        "he": "his",
        "she": "her",
        "it": "its",
        "we": "our",
        "they": "their",
        "this": "its",
        "that": "its",
        "these": "their",
        "those": "their",
    }
    engOBJPR = {
        "i": "me",
        "you": "you",
        "he": "him",
        "she": "her",
        "it": "it",
        "we": "us",
        "they": "them",
        "this": "it",
        "that": "it",
        "these": "them",
        "those": "them",
    }
    engPosObjConvert = {
        "me": "my",
        "you": "your",
        "him": "his",
        "her": "her",
        "it": "its",
        "us": "our",
        "them": "their",
    }
    case = 0
    results = []

    def __init__(self, part, cc):
        """Initializes the data."""
        self.result = []

        """Clean the conjunction from end of clause if any"""
        part = part.strip(" .")
        part = part.strip(".")
        if part.endswith(", and"):
            part = part[:-5]
        if part.endswith(" and"):
            part = part[:-3]

        """complete sentence matrix. As we will remove relative clause later, we will need a full matrix as well"""
        self.fullClause = part
        self.fullpartMatrix = sentMatrix(part)
        self.children = [[i for i in w.children] for w in nlp(part)]
        self.allwords = [w.text for w in nlp(part)]
        self.alldeps = [w.dep_ for w in nlp(part)]
        self.allposes = [w.pos_ for w in nlp(part)]
        self.alltags = [w.tag_ for w in nlp(part)]
        self.allheads = [w.head for w in nlp(part)]
        # print(self.children)
        # print(self.fullpartMatrix)

        """ Main update in V7. Checking for availability of a second relation inside the clause."""
        self.relCheck = False
        self.relationCheck = checkCause(part)
        if self.relationCheck:
            # cause2 = self.relationCheck[0]
            # effect2 = self.relationCheck[1]
            # mode2 = self.relationCheck[5]
            conversion2 = clineNoEffect(part)
            convRes = conversion2[1]
            convRes = convRes[0].lower() + convRes[1:]
            convRes = convRes.strip(".")
            if convRes != "Error" or convRes != "Skipped":
                self.relCheck = True
                self.result.append([convRes])
        else:
            pass

        """If there there are two verb phrases combined with 'and' nominalize them separately and join them and return"""
        self.allposesPattern = "-".join(self.allposes)
        self.secondVerb = []
        self.secondVerbIndex = ""
        self.secondConjunct = ""
        # check if there are two verbs for nominalization inside the clause
        if "VERB-CCONJ-VERB" in self.allposesPattern and (
            self.allwords[self.allposes.index("CCONJ")] == "and"
            or self.allwords[self.allposes.index("CCONJ")] == "or"
        ):

            firstVerb = self.allwords[self.allposes.index("CCONJ") - 1]
            secVerb = self.allwords[self.allposes.index("CCONJ") + 1]
            self.secondVerbIndex = self.allposes.index("CCONJ") + 1
            self.secondVerb.append((firstVerb, secVerb))
            self.secondConjunct = self.allwords[self.allposes.index("CCONJ")]

        elif (
            "CCONJ-VERB" in self.allposesPattern
            and self.allwords[self.allposes.index("CCONJ")] == "and"
            and self.alltags[self.allposes.index("CCONJ") + 1] != "VBG"
        ):
            cutFirstPart = self.allwords[: self.allposes.index("CCONJ")]
            cutFirstRes = smallClause(" ".join(cutFirstPart))
            cutSecondPart = self.allwords[self.allposes.index("CCONJ") + 1 :]
            cutSecondRes = smallClause(" ".join(cutSecondPart))
            if (
                cutFirstRes
                and cutSecondRes
                and "Error" not in cutFirstRes
                or "Skipped" not in cutFirstRes
                and "Error" not in cutSecondRes
                or "Skipped" not in cutSecondRes
            ):
                mixThem = "{} and {} ".format(cutFirstRes, cutSecondRes)
                self.result.append([mixThem])
            else:
                pass

        elif (
            "CCONJ-NOUN-VERB" in self.allposesPattern
            or "CCONJ-NOUN-ADV-VERB" in self.allposesPattern
            or "CCONJ-PRON-VERB" in self.allposesPattern
            or "CCONJ-PRON-ADV-VERB" in self.allposesPattern
        ):

            self.cutParts = []
            ab = self.fullpartMatrix.find("CCONJ")
            bb = list(np.where(ab == 0))[1]
            cutFirstPart = self.allwords[: bb[0]]
            cc = bb.tolist()
            cc.append(len(self.allwords))
            cutFirstRes = smallClause(" ".join(cutFirstPart))
            i = 0
            while i < len(cc) - 1:
                cutSecondPart = self.allwords[cc[i] + 1 : cc[i + 1]]
                cutRoot = sentTagger(" ".join(cutSecondPart))
                if cutRoot:
                    cutRootCheck = "-".join(cutRoot[0])
                    if (
                        cutRootCheck.startswith("NP-VP")
                        or cutRootCheck.startswith("NPP-VP")
                        or cutRootCheck.startswith("NPTH-VP")
                        or cutRootCheck.startswith("NP-NPTH-VP")
                    ):
                        cutSecondRes = smallClause(" ".join(cutSecondPart))
                        self.cutParts.append(cutSecondRes)
                    else:
                        cutSecondRes = self.allwords[bb[0] + 1 :]
                        cutSecondRes = " ".join(cutSecondRes)
                        self.cutParts.append(cutSecondRes)
                else:
                    cutSecondRes = self.allwords[bb[0] + 1 :]
                    cutSecondRes = " ".join(cutSecondRes)
                    self.cutParts.append(cutSecondRes)
                i += 1
            cutSecondRes = " and ".join(self.cutParts)
            mixThem = "{} and {} ".format(cutFirstRes, cutSecondRes)
            self.result.append([mixThem])

        else:
            pass

        """Tag the sentence with sentTagger(). 5 results will return which are assigned to variables accordingly."""
        self.taggedSent = sentTagger(part)
        # print("self.taggedSent",self.taggedSent)
        self.patternList = self.taggedSent[0]
        self.clausePrep = self.taggedSent[3]
        self.PrepPhrase = self.taggedSent[4]
        self.relativeClause = self.taggedSent[5]
        self.pattern = "-".join(self.taggedSent[0])
        self.tagSent = self.taggedSent[1]
        self.myRoot = self.taggedSent[2]
        self.dict = dict(zip(self.taggedSent[0], self.taggedSent[1]))
        self.verbPhrase = self.taggedSent[1][1]

        """If there is a relative clause, take it out and nominalize the sentence without it. 
        The 'relativeCaluse' will be used in the makeNounPhrase() after the direct objects."""
        if self.relativeClause:
            listoflist = any(isinstance(e, list) for e in self.tagSent)
            if listoflist:
                self.tagSent = [item for sublist in self.tagSent for item in sublist]
            self.part = " ".join(self.tagSent)
            self.sentence = self.part
            self.relativeClause = self.taggedSent[5]

        else:
            self.part = part
            self.sentence = part

        if self.PrepPhrase:
            self.PrepPhrase = "{},".format(self.PrepPhrase)

        """Get Dependencies and continue."""
        self.erCode = 0
        self.partCase = cc
        self.words = [w.text for w in nlp(self.part)]
        self.deps = [w.dep_ for w in nlp(self.part)]
        self.poses = [w.pos_ for w in nlp(self.part)]
        self.tags = [w.tag_ for w in nlp(self.part)]
        a = nlp(self.part)
        c = nlp(part)

        """We prepare 3 Python dictionaries from the tag sets:
        'self.clauseDict' (4 spaCy tag sets) and 'self.dict' (sentence patterns)"""
        b = [[x.text, x.pos_, x.tag_, x.dep_] for x in a]
        self.clauseDict = [dict.fromkeys(x[1:], x[0]) for x in b][0]

        d = [[x.text, x.pos_, x.tag_, x.dep_] for x in c]
        self.clauseDict2 = [dict.fromkeys(x[1:], x[0]) for x in d][0]

        # print("self.clauseDict2",self.clauseDict2)
        self.rootindex = self.deps.index("ROOT")
        self.myVerb = self.allwords[self.rootindex]
        self.root = nltk.stem.WordNetLemmatizer().lemmatize(self.myRoot, "v")

        self.adverb = self.clauseDict.get("ADV")
        # self.adverbs = self.clauseDict.get('advmod')
        self.adverbial = self.clauseDict.get("RB")
        self.dobject = self.dict.get("OBD")
        self.pobject = self.dict.get("OBI")
        self.advpEntry = self.dict.get("ADVP")
        self.verbphrase = self.dict.get("VP")

        if self.clauseDict.get("ADJ"):
            self.adject = self.clauseDict.get("ADJ")
        elif self.clauseDict.get("acomp"):
            self.adject = self.clauseDict.get("acomp")
        elif self.clauseDict.get("ccomp"):
            self.adject = self.clauseDict.get("ccomp")
        else:
            self.adject = None
        # print("452",self.adject)
        """Determine if there is a modal verb in the sentence. If thgere is modal and its head is root"""
        if (
            "MD" in self.alltags
        ):  # and self.alldeps[self.alltags.index("MD")+1] == "ROOT":
            self.modal = True
            self.modalWord = self.allwords[self.alltags.index("MD")]
            # print("HEREEE",self.modal,self.modalWord)
        else:
            self.modal = False

        """Determine if the sentence is active or passive"""
        self.nounPhrase = self.taggedSent[0][0]

        if self.nounPhrase == "NPP":
            self.active = False
            self.passive = True
        else:
            self.active = True
            self.passive = False

        """Human/Non-Human Subject is determined by looking into NNP. We consider all of them human as we do 
        not have gender recognition system."""

        self.nounMTX = sentMatrix(self.fullClause)
        self.nounMTXbeforeRoot = self.nounMTX[3][: self.rootindex]
        if "NNP" in self.nounMTXbeforeRoot or "NNPS" in self.nounMTXbeforeRoot:
            self.human = True
            if self.taggedSent[1][0].startswith("The"):
                # print(self.taggedSent[1][0])
                self.subject = (
                    self.taggedSent[1][0][0].lower() + self.taggedSent[1][0][1:]
                )
                # print(self.subject)
            else:
                self.subject = self.taggedSent[1][0]
        else:
            self.human = False
            self.subject = self.taggedSent[1][0].lower()

        """Working with pronouns. First, is the sentence subject a pronoun?"""
        if self.dict[self.nounPhrase].lower() in Clause.engSUBPR:
            self.humanSubPR = True
        else:
            self.humanSubPR = False

        """Pronoun Direct Object"""
        if (
            "OBD" in self.patternList
            and self.dict["OBD"].lower() in Clause.engObjPronouns
        ):
            self.humanOBD = True
        else:
            self.humanOBD = False

        """Pronoun Indirect Object"""
        if (
            "OBI" in self.patternList
            and self.dict["OBI"].lower() in Clause.engObjPronouns
        ):
            self.humanOBI = True
        else:
            self.humanOBI = False

        """Determine if verb has two parts e.g. 'carry out'. The dependency part is 'prt'."""
        if "prt" in self.deps:
            prtindex = self.deps.index("prt")
            self.prt = self.words[prtindex]
        else:
            self.prt = None

        """POS Converter for Noun Subject / Noun Subject Passive"""
        if "nsubjpass" in self.clauseDict:
            self.activeMode = False
        else:
            self.activeMode = True

        if self.humanSubPR and self.activeMode:
            self.pospron = Clause.engPOSPR.get(self.subject.lower())
        elif self.humanSubPR and not self.activeMode:
            self.pospron = Clause.engPOSPR.get(self.subject.lower())
        else:
            self.pospron = None

        """ Determine whether the sentence is a Positive/Negative Sentence"""
        self.neg = False
        if (
            "not" in self.dict["VP"]
            or "n't" in self.dict["VP"]
            or (
                "neg" in self.alldeps
                and str(self.allheads[self.alldeps.index("neg")]) == str(self.myRoot)
            )
            or (
                "neg" in self.alldeps
                and "acomp" in self.alldeps
                and str(self.allheads[self.alldeps.index("neg")])
                == str(self.words[self.alldeps.index("acomp")])
            )
        ):

            self.neg = True
        elif "to nothing" in self.part:
            self.neg = True
        elif self.passive and "none" in self.dict["NPP"]:
            noRemove = self.dict["NPP"].strip("none")
            self.neg = True

        # We use this for special negative handle later in Case 1 generation
        self.negING = False
        # print("541",self.neg,self.passive)

        """Processes Start Here"""
        self.checkLength()
        # self.modalCheck()
        # self.processNomals()
        self.vagueCheck()
        self.processRules()
        self.verbProcess()
        # self.wordExtractor()
        self.adverbWork()
        self.phraseGenerator()
        # self.wordPrinter()
        self.participleMaker()

    def verbProcess(self):
        """Main Nominalization of VERB happens here"""
        if self.neg and not self.secondVerb:
            # print("559", self.neg, self.result)
            # if ("have" in self.verbphrase or "has" in self.verbphrase or "had" in self.verbphrase) and ("aux" not in self.alldeps or "auxpass" not in self.alldeps):
            if self.root == "have":
                self.verbnomal = ["lack of"]
            else:
                self.verbAnt = Clause.antony(self, str(self.root), "v")
                # print("565",self.verbAnt)
                if self.verbAnt:
                    self.verbnomal = Clause.nomalize(
                        Clause.antony(self, str(self.root), "v"), None
                    )
                    if self.verbnomal:
                        resPos = sentMatrix(self.verbnomal[0])
                        if resPos.tolist()[3] == "JJ":
                            self.verbnomal = Clause.adjectify(self.verbnomal[0])
                        else:
                            self.verbnomal = self.verbnomal

        elif self.neg and self.secondVerb:
            self.verbnomal = Clause.antony(self, self.secondVerb, "v")

        elif not self.neg and self.secondVerb:
            self.verbnomal = Clause.nomalize(self.secondVerb, self.secondConjunct)

        else:
            self.verbnomal = Clause.nomalize(str(self.root), None)

    def participleMaker(self):
        # print("Here",self.humanSubPR)
        res = ""
        if Clause.case in [2, 3, 4, 5]:
            root = self.root
            remain = self.allwords[self.alldeps.index("ROOT") + 1 :]
            if self.passive and self.neg:
                if self.humanSubPR:
                    objectPR = str(Clause.engOBJPR.get(self.subject.lower()))
                    res = objectPR, "not to be", self.myVerb, " ".join(remain)
                    res = " ".join(res)
                else:
                    res = (
                        "the",
                        self.subject,
                        "not to be",
                        self.myVerb,
                        " ".join(remain),
                    )
                    res = " ".join(res)
            elif self.passive and not self.neg:
                if self.humanSubPR:
                    objectPR = str(Clause.engOBJPR.get(self.subject.lower()))
                    res = objectPR, "to be", self.myVerb, " ".join(remain)
                    res = " ".join(res)
                else:
                    res = "the", self.subject, "to be", self.myVerb, " ".join(remain)
                    res = " ".join(res)
            elif self.active and self.neg:
                if self.pospron:
                    res = self.pospron, "not to", self.root, " ".join(remain)
                    res = " ".join(res)
                else:
                    res = self.subject, "not to", self.root, " ".join(remain)
                    res = " ".join(res)
            elif self.active and not self.neg:
                if self.pospron:
                    res = self.pospron, "to", self.root, " ".join(remain)
                    res = " ".join(res)
                else:
                    res = self.subject, "to", self.root, " ".join(remain)
                    res = " ".join(res)
        else:
            res = self.part
        return res

    def wordPrinter(self):
        if Clause.case == 1:
            res = "{},{}".format(self.adjectmain, self.adjectnomal[0])
        else:
            if self.secondVerb:
                res = "{},{}".format(self.secondVerb, self.verbnomal[0])
            else:
                res = "{},{}".format(self.myVerb, self.verbnomal[0])
        # print(res)

    def phraseGenerator(self):
        print("Clause.case:", Clause.case)
        # print(self.part, Clause.case, self.pattern, self.allwords, self.root, self.subject, self.adject).
        remain = ""
        ofword = ""

        # if there is a modal verb, add drop-dwon list
        if self.modal and self.verbnomal:
            if self.modalWord in ["could", "may", "might"]:
                dropDown = "<select><option selected>possible</option><option>potential</option><option>planned</option></select> "
                self.verbnomal[0] = dropDown + self.verbnomal[0]

            elif self.modalWord in ["should", "will"]:
                dropDown = "<select><option selected>probable</option><option>likely</option></select> "
                self.verbnomal[0] = dropDown + self.verbnomal[0]
            elif self.modalWord in ["must"]:
                dropDown = "required "
                self.verbnomal[0] = dropDown + self.verbnomal[0]
            elif self.modalWord in ["can"] and self.neg:
                dropDown = "inability to "
                self.verbnomal[0] = dropDown + self.root
            elif self.modalWord in ["can"]:
                dropDown = "ability to "
                self.verbnomal[0] = dropDown + self.root

        elif (
            (self.pattern == "NP-VP" or self.pattern == "NPP-VP")
            and self.root == "be"
            and not self.neg
        ):
            Clause.case == 4

        if Clause.case == 1:
            self.verbnomal = "None"  # Our case1 does not need the nominalized verb
            # print('676',self.adjectnomal[0], self.result)
            # if isinstance(self.adjectnomal[0],list):
            # self.result.append(self.adjectnomal[0][0])
            # self.adjectnomal[0] = '[MASK]'
            # else:
            self.result.append(self.adjectnomal[0])
            self.adjectnomal[0] = "[MASK]"

            # Get remained part
            if self.secondAdjective:
                remain = self.allwords[self.secondAdjectiveIndex + 1 :]
            else:
                remain = self.allwords[
                    self.allwords.index(self.dict.get("ADJP")[-1]) + 1 :
                ]

            # Remove converted adverbs from remaining part
            if self.advConversions:
                for x in self.advConversions:
                    advToRemove = x[0]
                    if advToRemove in remain:
                        advIndex = remain.index(x[0])
                        remain.pop(advIndex)

            # Generate Sentence
            if self.human and len(self.subject.split()) == 1 and not self.neg:
                res = [
                    str(self.subject),
                    "'s",
                    str(self.advpRBR),
                    str(self.adjectnomal[0]),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) == 1 and self.negING:
                res = [
                    str(self.subject),
                    "'s",
                    str(self.advpRBR),
                    str(self.adjectnomal[0]),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1 and not self.neg:
                res = [
                    "the",
                    str(self.advpRBR),
                    str(self.adjectnomal[0]),
                    "of the",
                    str(self.subject),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1 and self.negING:
                res = [
                    "the",
                    str(self.advpRBR),
                    str(self.subject),
                    str(self.adjectnomal[0]),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.pospron and not self.neg:
                res = [
                    self.pospron,
                    str(self.advpRBR),
                    str(self.adjectnomal[0]),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.pospron and self.negING:
                res = [
                    self.pospron,
                    str(self.advpRBR),
                    str(self.adjectnomal[0]),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            else:
                if self.negING and not self.neg:
                    res = [
                        str(self.advpRBR),
                        str(self.subject),
                        str(self.adjectnomal[0]),
                        " ".join(remain),
                        str(self.advp),
                    ]
                    self.result.append(res)
                elif not self.negING and self.neg:
                    res = [
                        str(self.advpRBR),
                        str(self.adjectnomal[0]),
                        "of the",
                        str(self.subject),
                        remain,
                        str(self.advp),
                    ]
                    self.result.append(res)
                else:
                    res = [
                        "the",
                        str(self.advpRBR),
                        str(self.adjectnomal[0]),
                        "of the",
                        str(self.subject),
                        " ".join(remain),
                        str(self.advp),
                    ]
                    self.result.append(res)

        elif Clause.case == 2:
            self.result.append(self.verbnomal[0])
            self.verbnomal[0] = "[MASK]"
            # Get remained part
            if self.secondVerb:
                remain1 = self.allwords[self.secondVerbIndex + 1 :]
                remain = " ".join(remain1)
            else:
                remain1 = self.allwords[self.alldeps.index("ROOT") + 1 :]
                remain = " ".join(remain1)
            # Remove converted adverbs from remaining part
            if self.advConversions:
                for x in self.advConversions:
                    advToRemove = x[0]
                    if advToRemove in remain1:
                        advIndex = remain1.index(x[0])
                        remain1.pop(advIndex)
                        remain = " ".join(remain1)
            # If the remaining part starts with preposition tag (IN), we remove "of"
            if remain:
                ofword = remainCleaner(" ".join(remain), self.verbnomal[0])

            # Generate Sentence
            if self.human and len(self.subject.split()) == 1:
                res = [
                    self.subject,
                    "'s",
                    str(self.advpRBR),
                    self.verbnomal[0],
                    ofword,
                    remain,
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1 and self.neg:
                res = [
                    str(self.advpRBR),
                    self.subject,
                    self.verbnomal[0],
                    remain,
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1:
                res = [
                    "the",
                    str(self.advpRBR),
                    self.verbnomal[0],
                    ofword,
                    remain,
                    "by",
                    self.subject,
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.pospron:
                res = [
                    self.pospron,
                    str(self.advpRBR),
                    self.verbnomal[0],
                    ofword,
                    remain,
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.passive:
                res = [
                    self.pospron,
                    str(self.advpRBR),
                    self.verbnomal[0],
                    ofword,
                    remain,
                    str(self.advp),
                ]
                self.result.append(res)
            else:
                if self.neg:
                    res = [
                        str(self.advpRBR),
                        self.subject,
                        self.verbnomal[0],
                        remain,
                        str(self.advp),
                    ]
                    self.result.append(res)
                else:
                    res = [
                        "the",
                        str(self.advpRBR),
                        self.verbnomal[0],
                        ofword,
                        remain,
                        "by",
                        self.subject,
                        str(self.advp),
                    ]
                    self.result.append(res)

        elif Clause.case == 3:
            self.result.append(self.verbnomal[0])
            self.verbnomal[0] = "[MASK]"
            # Get remained part
            if self.secondVerb:
                remain = self.allwords[self.secondVerbIndex + 1 :]
            else:
                remain = self.allwords[self.alldeps.index("ROOT") + 1 :]
            # Remove converted adverbs from remaining part
            if self.advConversions:
                for x in self.advConversions:
                    advToRemove = x[0]
                    if advToRemove in remain:
                        advIndex = remain.index(x[0])
                        remain.pop(advIndex)

            # If the remaining part starts with preposition tag (IN), we remove "of"
            if remain:
                ofword = remainCleaner(" ".join(remain), self.verbnomal[0])
            # Generate Sentence
            if self.human and len(self.subject.split()) == 1:
                res = [
                    self.subject,
                    "'s",
                    str(self.advpRBR),
                    self.verbnomal[0],
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1 and self.neg:
                res = [
                    str(self.advpRBR),
                    self.subject,
                    self.verbnomal[0],
                    ofword,
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1:
                res = [
                    "the",
                    str(self.advpRBR),
                    self.verbnomal[0],
                    "of the",
                    self.subject,
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.pospron and self.neg and self.verbnomal[0] == "lack":
                res = [
                    self.pospron,
                    self.verbnomal[0],
                    "of",
                    str(self.advpRBR),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.pospron:
                res = [
                    self.pospron,
                    str(self.advpRBR),
                    self.verbnomal[0],
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            else:
                if self.neg:
                    res = [
                        str(self.advpRBR),
                        self.subject,
                        self.verbnomal[0],
                        " ".join(remain),
                        str(self.advp),
                    ]
                    self.result.append(res)
                else:
                    res = [
                        "the",
                        str(self.advpRBR),
                        self.verbnomal[0],
                        "of the",
                        self.subject,
                        " ".join(remain),
                        str(self.advp),
                    ]
                    self.result.append(res)
            # print("827",res)

        elif Clause.case == 4 or Clause.case == 5:
            self.result.append(self.verbnomal[0])
            self.verbnomal[0] = "[MASK]"
            # Get remained part
            if self.secondVerb:
                remain = self.allwords[self.secondVerbIndex + 1 :]
            else:
                remain = self.allwords[self.alldeps.index("ROOT") + 1 :]
            # Remove converted adverbs from remaining part
            if self.advConversions:
                for x in self.advConversions:
                    advToRemove = x[0]
                    if advToRemove in remain:
                        advIndex = remain.index(x[0])
                        remain.pop(advIndex)

            # Generate Sentence
            if self.human and len(self.subject.split()) == 1:
                res = [
                    self.subject,
                    self.verbnomal[0],
                    str(self.advpRBR),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.human and len(self.subject.split()) > 1:
                res = [
                    self.subject,
                    self.verbnomal[0],
                    str(self.advpRBR),
                    " ".join(remain),
                    "by",
                    str(self.advp),
                ]
                self.result.append(res)
            elif self.pospron:
                res = [
                    self.pospron,
                    str(self.advpRBR),
                    self.verbnomal[0],
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)
            else:
                res = [
                    self.subject,
                    self.verbnomal[0],
                    str(self.advpRBR),
                    " ".join(remain),
                    str(self.advp),
                ]
                self.result.append(res)

    def wordExtractor(self):
        """Exports the words that are nominalized for statistical use, coloring, POS conversion report"""
        wordResult = {}

        if self.pospron:
            wordResult[self.taggedSent[1][0]] = self.pospron

        if self.adverbs:
            for x in self.advConversions:
                wordResult[x[0]] = x[1]

        if Clause.case == 1:
            if self.secondAdjective:
                mycomb = " and ".join(self.adjectmain)
                wordResult[mycomb] = " ".join(self.adjectnomal)
            else:
                wordResult[self.adject] = " ".join(self.adjectnomal)
        else:
            if self.neg:
                negs = self.verbphrase
                myneg = " ".join(self.verbnomal)
                if myneg.endswith("OF"):
                    myneg = myneg.replace("OF", "")
                wordResult[self.verbphrase] = myneg
            else:
                negs = "None"
                if self.secondVerb:
                    mycomb = " and ".join(self.secondVerb[0])
                    wordResult[mycomb] = " ".join(self.verbnomal)
                else:
                    wordResult[self.myRoot] = " ".join(self.verbnomal)

        res = [(k, v) for k, v in wordResult.items()]

        nsubject = self.subject
        return wordResult

    def checkLength(self):
        """Ignore 2 words clauses and set the clause.case to 0 and exit"""
        if len(self.words) <= 1:
            Clause.case = 0
        return Clause.case

    def vagueCheck(self):
        """Check the Vague List and set the clause.case to 0 and exit"""
        for word in Clause.vagueStop:
            if word in self.words:
                # print("STOP WORD:", word)
                Clause.case = 0
        return Clause.case

    def modalCheck(self):
        """Check if the main verb is modal and set the clause.case to 0 and exit"""
        modals = [w for w in self.words if w in Clause.modalStop]
        if modals:
            Clause.case = 0
            self.erCode = 107
        return Clause.case, self.erCode

    def sentTime(self):
        """Checks the clause tense"""
        if self.clauseDict.get("VBD"):
            self.sentTiming = "past"
        elif "will" in self.clauseDict or "'ll" in self.clauseDict:
            self.sentTiming = "future"
        else:
            self.sentTiming = "present"

        return self.sentTiming

    def processRules(self):
        """Processes the clause to assign a Rule to it. Patterns are returned from sentTagger() in init function.
        Patterns are assigned in 5 cases. Adjectives in Case 1 need more attention because we have
        different type of adjective clauses. We assign 'adjectnomal'using below rule, considering two
        types of ADJP and ADJNM tags and also they can be positive and negative. Error codes 103, 104 and 105 are
        assigned in this function."""

        # Set the cases
        case1 = [
            "NP-VP-ADJNM",
            "NP-VP-ADJP-ADJNM",
            "NP-VP-ADJP-ADVP",
            "NP-VP-ADJP",
            "NP-VP-ADJP-OBI",
            "NP-VP-ADJP-OBI-ADVP",
            "NP-VP-OBPRD",
            "NP-VP-ADJP-OBI-ADJNM-ADVP",
            "NP-VP-ADJP-OBD",
            "NP-VP-ADJP-OBD-OBI",
            "NP-VP-ADJP-OBD",
        ]
        case2 = [
            "NP-VP-OBD",
            "NP-VP-OBD-ADVP",
            "NP-VP-OBD-OBI",
            "NP-VP-OBD-OBAPPOS",
            "NP-VP-OBD-OBI-OBAPPOS",
            "NP-VP-OBD-OBI-OBAPPOS-ADVP",
            "NP-VP-OBD-OBAPPOS-ADVP",
            "NP-VP-OBPRD-OBI",
        ]
        case3 = [
            "NPP-VP-OBI",
            "NP-VP",
            "NPP-VP",
            "NPP-VP-ADVP",
            "NP-VP-OBI",
            "NPP-VP-OBI-OBAPPOS",
            "NPP-VP-OBPRD",
            "NP-VP-OBI-ADVP",
            "NP-VP-OBI-NPAtt",
            "NP-VP-ADVP",
            "NPP-VP-OBI-ADVP",
            "NPP-VP-OBD",
        ]
        case4 = [
            "NP-VP-NPAtt",
            "NPTH-VP-OBI",
            "NP-NPTH-VP-OBI",
        ]  # e.g. She is a poor talker
        case5 = [
            "NPTH-VP-NPAtt",
            "NP-NPTH-VP-NPAtt",
            "NP-NPTH-VP-OBI-NPAtt",
            "NP-NPTH-VP-OBD-NPAtt",
        ]

        self.adjectmain = []
        self.secondAdjective = False
        self.adjectnomal = None

        if self.pattern in case1:
            if self.adject and self.adject == "be":
                Clause.case = 4

            # check if there are two adjective for nominalization inside the clause -- Update V.7
            if (
                "ADJ-CCONJ-ADJ" in self.allposesPattern
                and self.allwords[self.allposes.index("CCONJ")] == "and"
            ):
                myIndex = self.allposes.index("CCONJ")
                firstAdj = self.allwords[myIndex - 1]
                secondAdj = self.allwords[myIndex + 1]
                self.secondConjunct = "and"
                self.adjectmain.append(firstAdj)
                self.adjectmain.append(secondAdj)
                self.secondAdjective = True
                self.secondAdjectiveIndex = myIndex + 1
                if self.neg:
                    self.adjectnomal = Clause.adjectify(
                        Clause.antony(self, self.adjectmain, "a")
                    )
                    print("962", self.adjectmain, self.adjectnomal[0])
                else:
                    self.adjectnomal = Clause.adjectify(self.adjectmain)
                # print('961',self.adjectnomal)

            elif (
                "ADJ-CCONJ-ADV-ADJ" in self.allposesPattern
                and self.allwords[self.allposes.index("CCONJ")] == "and"
            ):
                myIndex = self.allposes.index("CCONJ")
                firstAdj = self.allwords[myIndex - 1]
                secondAdj = self.allwords[myIndex + 2]
                self.adjectmain.append(firstAdj)
                self.adjectmain.append(secondAdj)
                self.secondAdjective = True
                self.secondAdjectiveIndex = myIndex + 2
                if self.neg:
                    self.adjectnomal = Clause.adjectify(
                        Clause.antony(self, self.adjectmain, "a")
                    )
                else:
                    self.adjectnomal = Clause.adjectify(self.adjectmain)
                print("975", self.adjectnomal)

            elif (
                self.dict.get("ADJP")
                and len(self.dict.get("ADJP")) >= 1
                and self.neg == False
            ):
                self.adjectmain = self.dict.get("ADJP")[-1]
                a = Clause.adjectify(self.adjectmain)
                if a:
                    b = " ".join(a)
                else:
                    b = "None"
                self.adjpFirstPart = self.dict.get("ADJP")[:-1]
                self.adjectnomal = [" ".join(self.adjpFirstPart).replace(" -", "-"), b]
                self.adjectnomal = ["".join(self.adjectnomal)]
                print("987", self.adjectnomal)
            elif (
                self.dict.get("ADJNM")
                and len(self.dict.get("ADJNM")) >= 1
                and self.neg == False
            ):
                self.adjectmain = self.dict.get("ADJNM")[-1]
                a = Clause.adjectify(self.adjectmain)
                if a:
                    b = " ".join(a)
                else:
                    b = "None"
                self.adjpFirstPart = self.dict.get("ADJNM")[:-1]
                self.adjectnomal = [" ".join(self.adjpFirstPart).replace(" -", "-") + b]
                print("997", self.adjectnomal)
            elif (
                self.dict.get("ADJP")
                and len(self.dict.get("ADJP")) >= 1
                and self.neg == True
            ):
                self.adjectmain = self.dict.get("ADJP")[-1]
                a = Clause.adjectify(Clause.antony(self, self.adjectmain, "a"))
                if a:
                    b = " ".join(a)
                else:
                    b = "None"
                self.adjpFirstPart = self.dict.get("ADJP")[:-1]
                self.adjectnomal = [" ".join(self.adjpFirstPart).replace(" -", "-") + b]
                print("1007", self.adjectnomal)
            elif (
                self.dict.get("ADJNM")
                and len(self.dict.get("ADJNM")) >= 1
                and self.neg == True
            ):
                self.adjectmain = self.dict.get("ADJNM")[-1]
                a = Clause.adjectify(Clause.antony(self, self.adjectmain, "a"))
                if a:
                    b = " ".join(a)
                else:
                    b = "None"
                self.adjpFirstPart = self.dict.get("ADJNM")[:-1]
                self.adjectnomal = [" ".join(self.adjpFirstPart).replace(" -", "-") + b]
                print("1017", self.adjectnomal)
            else:
                self.adjectmain = self.dict.get("ADJP")[-1]
                self.adjectnomal = Clause.adjectify(self.adjectmain)
                print("1021", self.adjectnomal)

            if self.adjectnomal:
                Clause.case = 1
            else:
                Clause.case = 0
                self.erCode = 103

        elif self.pattern in case2:
            Clause.case = 2
        elif self.pattern in case3:
            if (
                (
                    self.pattern == "NP-VP"
                    or self.pattern == "NP-VP-OBI"
                    or self.pattern == "NP-VP-OBD"
                )
                and (self.root == "be" or self.root == "'s" or self.root == "'re")
                and self.subject in ["it", "this", "that", "those", "these", "there"]
            ):
                Clause.case = 0
                # self.erCode = 104
            else:
                Clause.case = 3
        elif self.pattern in case4:
            Clause.case = 4
        elif self.pattern in case5:
            Clause.case = 5
        else:
            self.checkPossiblePattern()
            # Clause.case = 0
            # self.erCode = 105
        if self.pattern == "NP-VP-OBI" and self.root == "be":
            Clause.case = 4
        # print("Clause.case",Clause.case,self.erCode)
        return Clause.case

    def checkPossiblePattern(self):
        if "ADJNM" in self.pattern or "ADJP" in self.pattern:
            Clause.case = 1
            self.erCode = 0
        elif "NPP" in self.pattern:
            Clause.case = 3
            self.erCode = 0
        elif "NP-VP" in self.pattern:
            Clause.case = 2
            self.erCode = 0
        else:
            Clause.case = 0
            self.erCode = 105
        return Clause.case, self.erCode

    def adverbWork(self):
        """ ADVERBS AREA"""
        self.adverbs = []
        self.advp = []
        self.advpRBR = []
        self.advpInit = None
        self.advpInside = None
        self.advConversions = []
        self.advtext = None
        matrix = nlp(self.fullClause)
        words = [x.text for x in matrix]

        for possible_adv in matrix:
            if (
                possible_adv.dep == advmod
                and possible_adv.head.dep_ != "relcl"
                and possible_adv.pos_ != "ADJ"
                and not possible_adv.text.startswith("wh")
            ):
                self.adverbs.append(
                    [
                        possible_adv.text,
                        str(possible_adv.head),
                        possible_adv.head.dep_,
                        words.index(possible_adv.text),
                    ]
                )
        # print(Clause.case, self.adverbs, self.adjectmain,self.verbnomal)

        if self.adverbs:
            # check clause case, if case is 1, advs modifying acomp are advpRBR
            # if else, advs modifying root are advp
            self.adverbs = [x for x in self.adverbs if str(x[1]) != "relcl"]
            # chech if index is less than 1, set self.advpInit
            for advb in enumerate(self.adverbs):
                if advb[1][3] == 0:
                    self.adverbs.pop(advb[0])
                    self.advpInit = advb[1][0]
                    self.advtext = self.advpInit
                # join adverb head in e.g 'more easily'. Combine two adverbs take Deps from second. Adv2Adj converts both words
                elif len(self.adverbs) > 1 and advb[1][2] == "advmod":
                    advcombo = [advb[1][0], advb[1][1]]
                    advcombo = " ".join(advcombo)
                    self.advtext = advcombo
                    secondAdverb = self.adverbs[advb[0] + 1]
                    firstAdverb = self.adverbs[advb[0]]
                    firstAdverb = [advcombo] + secondAdverb[1:]
                    self.adverbs[advb[0]] = firstAdverb
                    self.adverbs = [
                        x for x in self.adverbs if str(x[0]) != str(advb[1][1])
                    ]
                else:
                    pass

            # print(self.adverbs)
            if Clause.case == 1:
                for adv in self.adverbs:
                    adv_text = adv[0]
                    adv_head = str(adv[1])
                    adv_headdep = adv[2]

                    if adv_text == "more" and (
                        adv_headdep == "acomp"
                        or adv_headdep == "ccomp"
                        or adv_headdep == "xcomp"
                    ):
                        adv_convert = "greater"
                        self.advpRBR.append(adv_convert)
                        self.advConversions.append((adv_text, adv_convert))
                    elif adv_text == "very" and self.root == "have":
                        adv_convert = "very"
                        self.advpRBR.append(adv_convert)
                        self.advConversions.append((adv_text, adv_convert))
                    elif adv_headdep != "ROOT":
                        adv_convert = adv2adj(adv_text)
                        if adv_convert:
                            self.advpRBR.append(adv_convert)
                            self.advConversions.append((adv_text, adv_convert))
                    else:
                        adv_convert = adv2adj(adv_text)
                        if adv_convert:
                            self.advp.append(adv_convert)
                            self.advConversions.append((adv_text, adv_convert))
            else:
                for adv in self.adverbs:
                    adv_text = adv[0]
                    adv_head = str(adv[1])
                    adv_headdep = adv[2]

                    if adv_text == "more" and (
                        adv_headdep == "acomp"
                        or adv_headdep == "ccomp"
                        or adv_headdep == "xcomp"
                    ):
                        adv_convert = "greater"
                        self.advpRBR.append(adv_convert)
                        self.advConversions.append((adv_text, adv_convert))
                    elif adv_text == "very" and self.root == "have":
                        adv_convert = "very"
                        self.advpRBR.append(adv_convert)
                        self.advConversions.append((adv_text, adv_convert))
                    elif adv_headdep == "ROOT":
                        adv_convert = adv2adj(adv_text)
                        if adv_convert:
                            self.advpRBR.append(adv_convert)
                            self.advConversions.append((adv_text, adv_convert))
                    elif adv_headdep in ["xcomp", "amod", "acomp"]:
                        adv_convert = adv2adj(adv_text)
                        if adv_convert:
                            self.advpRBR.append(adv_convert)
                            self.advConversions.append((adv_text, adv_convert))

                    else:
                        adv_convert = adv2adj(adv_text)
                        if adv_convert:
                            self.advp.append(adv_convert)
                            self.advConversions.append((adv_text, adv_convert))

        else:
            self.advp = None
            self.advpRBR = None
            self.advpInit = None
            self.advpInside = None

        # If we have changed an adverb, we need to remove it from OBD and OBI
        if "OBD" in self.pattern and self.advConversions:
            for entry in self.advConversions:
                if entry[0] in self.dobject:
                    advToRemove = entry[0]
                    self.dobject = self.dict["OBD"].replace(advToRemove, "")

        elif "OBI" in self.pattern and self.advConversions:
            for entry in self.advConversions:
                if entry[0] in self.pobject:
                    advToRemove = entry[0]
                    self.pobject = self.dict["OBI"].replace(advToRemove, "")

        # convert empty lists to Null
        if self.advp:
            self.advp = " ".join(self.advp)
        else:
            self.advp = None
        if self.advpRBR:
            self.advpRBR = " ".join(self.advpRBR)
        else:
            self.advpRBR = None

        # print("",self.advConversions)
        return self.advConversions

    def getResult(self):
        """Checks and sends the selected final clause output to cline()."""
        # print('GETRESULT',self.result)

        # Neural Language Model Noun Query
        word = self.result[0]
        # print("1210",word)
        sent = [x for x in self.result[1] if x != "None"]
        self.query = []
        if isinstance(word, list):
            # print('1213',word)

            if not self.neg:
                res = []
                for w in word:
                    if Clause.case == 1:
                        w = nltk.stem.WordNetLemmatizer().lemmatize(w, "a")
                    else:
                        w = nltk.stem.WordNetLemmatizer().lemmatize(w, "v")
                    keywords = get_nouns(w.lstrip().rstrip())
                    # print(keywords)
                    query = neural_api(" ".join(sent), keywords, "bert", "list")
                    if query:
                        res.append(query[0])
                if res:
                    out = " and ".join(res)
                    myindex = self.result[1].index("[MASK]")
                    self.result[1][myindex] = out
            else:
                myindex = self.result[1].index("[MASK]")
                self.result[1][myindex] = self.result[0][0]
        else:
            if "not" not in word:
                if Clause.case == 1:
                    word = nltk.stem.WordNetLemmatizer().lemmatize(word, "a")
                else:
                    word = nltk.stem.WordNetLemmatizer().lemmatize(word, "v")
                keywords = get_nouns(word.lstrip().rstrip())
                # print(keywords)
                self.query = neural_api(" ".join(sent), keywords, "bert", "list")
                if self.query:
                    myindex = self.result[1].index("[MASK]")
                    self.result[1][myindex] = self.query[0]
            else:
                myindex = self.result[1].index("[MASK]")
                self.result[1][myindex] = word

        # Return the result if there is a result
        if Clause.case != 0:
            # Gets the POS conversions and include them in the output
            self.posCovertion = self.wordExtractor()
            self.participle = self.participleMaker()
            if self.result:
                res = [x for x in self.result[1] if x != "None"]
                res = " ".join(res)
                return (
                    res,
                    Clause.case,
                    self.erCode,
                    self.posCovertion,
                    self.PrepPhrase,
                    self.advpInit,
                    self.relCheck,
                    self.participle,
                    self.query,
                )
            else:
                sent = "{}".format(self.sentence)
                return (
                    sent,
                    Clause.case,
                    self.erCode,
                    self.posCovertion,
                    self.PrepPhrase,
                    self.advpInit,
                    self.relCheck,
                    self.participle,
                    self.query,
                )
        else:
            sent = "{}".format(self.sentence)
            self.posCovertion = []
            self.participle = []
            return (
                sent,
                Clause.case,
                self.erCode,
                self.posCovertion,
                self.PrepPhrase,
                self.advpInit,
                self.relCheck,
                self.participle,
                self.query,
            )

    """Verb nominalizer function"""

    def nomalize(myword, conjunct):
        if isinstance(myword[0], tuple):
            res = list(myword[0])
        else:
            res = myword
        return [res]

    def adjectify(self):
        # print('1266 Adjectify: ',self)
        """Nominalizes the ADJECTIVES"""
        return [self]

    def antony(self, myword, pos):
        # print("1271", myword, pos)
        mycase = Clause.case
        passive = self.passive

        if myword == "know" and pos == "v" and self.passive:
            res = "not being known"
            return res

        antonymRaw = []
        if type(myword) is list:
            antys = []
            for item in myword[0]:
                for x in antonymData:
                    if item == x[1]:
                        antys.append(x[2])
                    elif item == x[2]:
                        antys.append(x[1])
                if antys:
                    antonymRaw.append(antys[0])
        else:
            antys = []
            for x in antonymData:
                if myword == x[1]:
                    antys.append(x[2])
                elif myword == x[2]:
                    antys.append(x[1])
            if antys:
                antonymRaw.append(antys[0])

        output = []
        if not antonymRaw and type(myword) is not list:
            output = negativeMaker(myword, pos, passive)
            res = output[0]
            self.negING = output[1]
            self.neg = output[2]
            return res

        # if two words for anotonym, take first one, add ing to second one
        elif not antonymRaw and type(myword) is list and pos == "v":
            firstWord = negativeMaker(myword[0][0], pos, passive)
            secondWord = ingMaker(myword[0][1], pos)
            res = "{} {} {}".format(firstWord[0], self.secondConjunct, secondWord[0])
            res = res.replace("OF", "")
            self.neg = firstWord[2]
            self.negING = firstWord[1]
            # print('1329', res)
            return [res]

        elif not antonymRaw and type(myword) is list and pos == "a":
            firstWord = negativeMaker(myword[0], pos, passive)
            secondWord = negativeMaker(myword[1], pos, passive)
            res = "{} {} {}".format(firstWord[0], self.secondConjunct, secondWord[0])
            res = res.replace("OF", "")
            self.neg = firstWord[2]
            self.negING = firstWord[1]
            # print('1339',res,self.secondConjunct)
            return [res]
        else:
            if len(antonymRaw) > 1:
                res = " ".join(antonymRaw)
                return res
            else:
                res = antonymRaw[0]
                return res

    def antonyOLD(self):
        """Nominalize the Antonym for Negative Clauses"""
        myword = self
        synonyms = []
        antonyms = []
        if type(myword) is list:
            for item in myword[0]:
                antys = []
                for syn in wordnet.synsets(item):
                    for l in syn.lemmas():
                        synonyms.append(l.name())
                        if l.antonyms():
                            if not antys:
                                antys.append(l.antonyms()[0].name())
                if antys:
                    antonyms.append(antys[0])
        else:
            antys = []
            for syn in wordnet.synsets(self):
                for l in syn.lemmas():
                    synonyms.append(l.name())
                    if l.antonyms():
                        if not antys:
                            antys.append(l.antonyms()[0].name())
            if antys:
                antonyms.append(antys[0])

        if not antonyms:
            return None
        else:
            if len(antonyms) > 1:
                res = " ".join(antonyms)
                return res
            else:
                return antonyms[0]


def ingMaker(myword, pos):
    # print('1378',myword,pos)

    res = []
    comb = []
    pastps = []
    if isinstance(myword, tuple):
        for w in myword:
            word = nltk.stem.WordNetLemmatizer().lemmatize(w, pos)
            mypastp = [x[2] for x in englishPastParticiples if x[0] == word]
            if mypastp:
                base = word
                pastp = mypastp[0]
            else:
                if word.endswith("e") and word not in ["be", "see", "die"]:
                    base = word[:-1]
                    pastp = word + "d"
                else:
                    base = word
                    pastp = word + "ed"

            if base == "die":
                base = "dy"
            elif base.endswith("e") and base not in ["be", "see", "die"]:
                base = base.strip("e")
            comb.append(base)
            pastps.append(pastp)

    else:
        word = nltk.stem.WordNetLemmatizer().lemmatize(myword, pos)
        mypastp = [x[2] for x in englishPastParticiples if x[0] == word]
        if mypastp:
            base = word
            pastp = mypastp[0]
        else:
            if word.endswith("e") and word not in ["be", "see", "die"]:
                base = word[:-1]
                pastp = word + "d"
            else:
                base = word
                pastp = word + "ed"

        if base == "die":
            base = "dy"
        elif base.endswith("e") and base not in ["be", "see", "die"]:
            base = base.strip("e")
        res.append(("{}ing".format(base), pastp))

    if res:
        return res[0]
    elif comb:
        joinedcomb = "{}ing and {}ing".format(comb[0], comb[1])
        return joinedcomb, pastps


def negativeMaker(myword, pos, passive):
    # print('1408',myword,pos,passive)
    ingWord = ingMaker(myword, pos)
    base = ingWord[0]
    pastp = ingWord[1]
    neg = True

    if pos == "v" and passive:
        res = "not being {}".format(pastp)
        negING = True
    elif pos == "a":
        res = "not being {}".format(myword)
        neg = True
        negING = True
    else:
        if base == "die":
            base = "dy"
        elif base.endswith("e") and base not in ["be", "see", "die"]:
            base = base.strip("e")
        res = "not {} OF".format(base)
        negING = True
    # print('1425',res,negING,neg)
    return res, negING, neg


def remainCleaner(sent, verbPhrase):
    process = sentMatrix(sent)
    tags = process[3].tolist()
    if verbPhrase != "None" and verbPhrase.startswith("to"):
        ofword = "None"
    elif verbPhrase == "None" and tags[0] == "IN":
        ofword = "None"
    elif verbPhrase == "None" and tags[0] != "IN":
        ofword = "of"
    elif tags[0] == "IN":
        ofword = "None"
    else:
        ofword = "of the"
    return ofword


def smallClause(sent):
    res = Clause(sent, "C").getResult()
    res1 = res[0].strip(".")
    res1 = res1.strip()
    if res1.endswith("by"):
        res1 = res1.strip("by")
    elif res1.endswith("by."):
        res1 = res1.strip("by.")
    res1 = sentCleaner(res1)
    return res1


def neural_api(sent, keywords, model, mode):
    keys = keywords
    tokens = ["[CLS]"] + sent.split() + ["[SEP]"]
    mask_index = tokens.index("[MASK]")
    indices = [i for i, val in enumerate(tokens) if val == "[MASK]"]
    results = []
    for index in indices:
        keyindex = indices.index(index)
        sentence = " ".join(tokens)
        input_ids = torch.tensor(langmodel.bert_tokenizer.encode(sentence)).unsqueeze(0)
        outputs = langmodel.bert_model(input_ids, masked_lm_labels=input_ids)
        pre = outputs[1].topk(10000)
        words = pre[1]
        best_words = words[0][index]
        scores = pre[0]
        best_scores = scores[0][index]
        predictions = [
            langmodel.bert_tokenizer.convert_ids_to_tokens(x.tolist())
            for x in best_words
        ]
        res = zip(predictions, [x.item() for x in best_scores])
        sorted_data = sorted(res, key=lambda x: x[1], reverse=True)
        # print("Sorted",sorted_data)
        predicts = [x[0] for x in sorted_data if x[0] in keys]
        if predicts:
            results.append(predicts[0])
    if results:
        return results
    else:
        return keys


def neural_api2(sent, word, model, mode):
    word = list(set(word))
    words = ",".join(word)
    base_url = "http://hega.lt.cityu.edu.hk:8002/?model={}&mode={}&".format(model, mode)
    url_sent = "sent={}".format(quote(sent), safe="")
    url_keywords = "&words={}".format(quote(words), safe="")
    api_url = base_url + url_sent + url_keywords
    # print(api_url)
    with urllib.request.urlopen(api_url) as url:
        data = json.loads(url.read().decode())
        out = []
        for x in data:
            a = list(x["Result"].items())
            b = [(n[0], float(n[1])) for n in a]
            sorted_data = sorted(b, key=lambda x: x[1], reverse=True)
            predicts = sorted_data[0:1]
            if predicts:
                out.append(predicts)
                return out[0][0]
            else:
                return word


def get_nouns(word):
    res = [x[2:] for x in CatvarNomlexLee if x and word in x]
    res = [x for x in res[0] if x != ""]
    return res


def catvarCheck(word):
    """CATVAR Dictionary"""
    result = []
    for x in catvardicts:
        for k, v in x.items():
            if word in v:
                result.append(x.get("N"))
    if not result:
        phrase = "{}".format(word)
        # word = ['No_NOUN']
        return [phrase]
    else:
        return result[0]


def adv2adj(word):
    """ADVERB TO ADJECTIVE"""
    result = []
    words = word.split()
    for w in words:
        for entry in adv2adjBank:
            if w == entry[0]:
                # print(entry[2])
                result.append(entry[1])
    if result:
        result = " ".join(result)
        return result
    else:
        res = "{}".format(word)
        return word


def stanfordMatrix(sent):
    """Stanford Parser Matrix. We currently do not use it. It is reserved for futrue, just in case."""
    sent = sent.rstrip(",.'?!#")
    sent = quote(sent.encode("utf8"))
    url = "http://mega.lt.cityu.edu.hk:1212/get?text={}".format(sent)
    contents = urllib.request.urlopen(url).read()
    contents = contents.decode("utf-8")
    contents = contents.replace("~", ",")
    contents = re.sub(r"\([^)]*\)", "", contents)
    contents = re.sub(r"[0-9]\-", "", contents)
    contents = contents.split("\n")
    contents = [x.split(",") for x in reversed(contents)]
    words = list(filter(None, contents[0]))
    deps = list(filter(None, contents[1]))
    poses = list(filter(None, contents[2]))
    tags = list(filter(None, contents[2]))
    all_list = [words, deps, poses, tags]
    # print(all_list)
    arr = np.array(all_list, dtype="str").view(np.chararray)
    # print(arr)
    return arr


def sentMatrix(sent):
    """Sentence Matrix. We use a Numpy matrix of 4 spaCy tags extensively in the system. It gives us the freedom to find any type of dependency or POS tag easily without a need to use too many codes to move between the different tag sets."""
    words = [w.text for w in nlp(sent)]
    deps = [w.dep_ for w in nlp(sent)]
    poses = [w.pos_ for w in nlp(sent)]
    tags = [w.tag_ for w in nlp(sent)]
    heads = [w.head for w in nlp(sent)]
    children = [w.children for w in nlp(sent)]
    all_list = [words, deps, poses, tags, heads, children]
    arr = np.array(all_list, dtype="str").view(np.chararray)
    # print(arr)
    return arr


def sentTime(sent):
    """Sentence Time"""
    matrix = sentMatrix(sent)
    a = matrix.find("ROOT")
    b = list(np.where(a == 0))[1]
    verb = sent[int(b.tolist()[0])]
    sentStart = sent[: int(b.tolist()[0])]
    mtx = sentMatrix(sentStart)
    verbStem = nltk.stem.WordNetLemmatizer().lemmatize(verb, "v")
    if "VBD" in matrix[3]:
        sentVerb = "caused"
        time = "past"
    elif "will" in matrix[0] or "'ll" in matrix[0]:
        sentVerb = "will cause"
        time = "future"
    elif "NNS" in matrix[3][: b[0]]:
        sentVerb = "cause"
        time = "present"
    else:
        sentVerb = "causes"
        time = "present"
    return sentVerb, time


def expressionTime(sent):
    """Sentence Time for backward sentence generation in Expression Class"""
    mtx = sentMatrix(sent)
    rootIndex = mtx[1].tolist().index("ROOT")
    rootTag = mtx[3].tolist()[rootIndex]
    tense_list = {
        "VB": "base",
        "VBD": "past",
        "VBG": "gerund",
        "VBN": "pastp",
        "VBP": "present",
        "VBZ": "third",
    }
    rootTense = tense_list.get(rootTag)
    prevTense = None

    if rootTense == "base" and mtx[0].tolist()[rootIndex - 1] in ["'ll", "will"]:
        prevTense = "future"

    elif (rootTense == "gerund" or rootTense == "pastp" or rootTense == "base") and mtx[
        3
    ].tolist()[rootIndex - 1]:
        prev_dep = mtx[1].tolist()[rootIndex - 1]
        if (
            prev_dep == "neg"
        ):  # if previous tag is neg go one word back further to the modal verb
            prev_tag = mtx[3].tolist()[rootIndex - 2]
        else:
            prev_tag = mtx[3].tolist()[rootIndex - 1]
        prevTense = tense_list.get(prev_tag)

    if prevTense:
        return prevTense
    else:
        return rootTense


def clausekit(sent):
    """This is our main keyspotting function. It mixes the Clause Cutter with key spotting and uses the location of Noun Subject/Noun Subject Passive to cut the sentence into two clauses."""
    clauses = []
    output = []
    words = [w.text for w in nlp(sent)]
    deps = [w.dep_ for w in nlp(sent)]
    if deps[-1] == "punct":
        words = words[:-1]
    # Looks for Mark Keywords in sentence
    if "mark" in deps:
        markIndex = deps.index("mark")
        a = words[0:markIndex]
        b = words[markIndex + 1 :]
        output.append(" ".join(a))
        output.append(" ".join(b))

    # If there is no mark, cuts the sentence based on Nsubj/Nsubjpass location
    else:
        cutPoints = [i for i, x in enumerate(deps) if x == "nsubj" or x == "nsubjpass"]
        if len(cutPoints) == 1:
            output.append(sent)
        else:
            cutPoints = zip(cutPoints, cutPoints[1:])
            for x in cutPoints:
                a = words[x[0] : x[1]]
                b = words[x[1] :]
                clauses.append(a)
                clauses.append(b)
            result = [c for c in clauses if len(c) != len(words)]

            cleanDep = ["cc", "det", "conj", "prep", "intj"]
            punctClean = []
            for r in result:
                cdeps = [w.dep_ for w in nlp(" ".join(r))]
                n = 0
                if (
                    len(
                        [
                            i
                            for i, x in enumerate(cdeps)
                            if x == "nsubj" or x == "nsubjpass"
                        ]
                    )
                    == 1
                ):
                    if "punct" in cdeps:
                        x1 = r[: cdeps.index("punct")]
                        punctClean.append(x1)
                    else:
                        punctClean.append(r)
            for p in punctClean:
                a = [[x.text, x.dep_] for x in nlp(" ".join(p))]
                b = [dict.fromkeys(x[1:], x[0]) for x in a]
                cdict = {v: k for b in b for k, v in b.items()}
                # print(cdict)
                x = [x for x in p if (cdict.get(x) not in cleanDep or p.index(x) != -1)]
                output.append(" ".join(x))

    return output


def checkCause(sentence):
    """The main function to determine if the sentence is causative so we can proceed with the processing the sentence.
    it returns False, if the sentence is not causative."""
    # print(sentence)
    # sentence = sentence[0].lower()+sentence[1:]
    arr = sentMatrix(sentence)
    words = list(arr[0])
    deps = list(arr[1])
    poses = list(arr[2])
    tags = list(arr[3])

    if deps[-1] == "punct":
        words = words[:-1]

    keywords = [
        "after",
        "After",
        "before",
        "Before",
        "until",
        "Until",
        "once",
        "Once",
        "even though",
        "Even though",
        "though",
        "Though",
        "due to",
        "Due to",
        "owing to the fact that",
        "Owing to the fact that",
        "as a result of",
        "As a result of",
        "as a result",
        "As a result",
        "because of",
        "Because of",
        "because",
        "Because",
        "thus",
        "Thus",
        "therefore",
        "Therefore",
        "since",
        "Since",
        "consequently",
        "Consequently",
        "but",
        "But",
        "although",
        "Although",
        "while",
        "While",
        "despite",
        "Despite",
        "even if",
        "Even if",
        "if",
        "If",
        "even when",
        "Even when",
        "even yet",
        "Even yet",
        "whether",
        "Whether",
        "whereas",
        "Whereas",
        "and so",
        "so",
    ]

    keywordLocation = [
        x
        for x in words
        if x in keywords
        and (
            deps[words.index(x)] == "mark"
            or deps[words.index(x)] == "advmod"
            or deps[words.index(x)] == "intj"
            or deps[words.index(x)] == "cc"
        )
    ]
    if keywordLocation:
        pass
    else:
        return False

    result = []
    comp = []
    compound = ""
    if "mark" in deps and words[deps.index("mark")] in keywords:
        markIndex = deps.index("mark")
        markWord = words[markIndex]
        preWord = words[markIndex - 1]
        compound = "{} {}".format(
            preWord, markWord
        )  # needs this to get full keyword to calculate length of keyword
        if compound in keywords:
            comp.append([preWord, markWord])
        else:
            comp.append([markWord])
        if markIndex < 2:
            status = "start"
        else:
            status = "middle"
        res = markWord, status
        result.append(res)
    else:
        for key in keywords:
            rx = r"\b{0}\b".format(key)
            search = re.search(rx, sentence)
            if search:
                keyIndex = sentence.find(key)
                if keyIndex < 2:
                    status = "start"
                else:
                    status = "middle"
                res = key, status
                comp.append([key])
                result.append(res)
    if comp:
        res = " ".join(comp[0]), status
        result[0] = res
    if result:
        keyword = result[0][0].lower()
        status = result[0][1]
        secondSubjCut = ""
        # We get second subject (passive or active) which is followed by a punctuation to cut the sentence later
        subjs = arr.find("nsubj")
        subjsIndice = list(np.where(subjs == 0))[1]
        if status == "start" and len(subjsIndice) > 1:
            lefts = [
                (subjsIndice[1] - 1, deps[subjsIndice[1] - 1]),
                (subjsIndice[1] - 2, deps[subjsIndice[1] - 2]),
                (subjsIndice[1] - 3, deps[subjsIndice[1] - 3]),
            ]
            for x in lefts:
                if "punct" in x:
                    secondSubjCut = x[0]

        # We use the punctuation before the second subject to cut the sentence
        if status == "start":
            key = [keyword]
            # print(key)
            if secondSubjCut:
                keyIndex = secondSubjCut
            else:
                if "punct" in deps:
                    keyIndex = deps.index("punct")
                else:
                    return False
            firstPart = words[len(comp[0]) : keyIndex]
            secondPart = words[keyIndex + 1 :]

        # The location of keyword first word is used to cut sentence
        elif status == "middle":
            if compound in keywords:
                key = keyword.split()
                firstPart = words[: markIndex - 1]
                secondPart = words[markIndex:]
            else:
                key = keyword
                keyIndex = words.index(key)
                # print('####',keyIndex,key)
                firstPart = words[:keyIndex]
                secondPart = words[keyIndex + 1 :]
                # print(key, firstPart, secondPart)

    else:
        return False

    # Recognition of "cause" and "effect" parts based on cue words
    # The RULE for Recognizing which part is cause, which one is effect

    midKeys = [
        "therefore",
        "affect",
        "cause",
        "happen",
        "consequently",
        "however",
        "still",
        "whereas",
        "thus",
        "and so",
        "so",
    ]
    startmidKeys = [
        "when",
        "When",
        "after",
        "After",
        "before",
        "Before",
        "until",
        "Until",
        "once",
        "Once",
        "as soon as",
        "As soon as",
        "as",
        "As",
        "even though",
        "Even though",
        "though",
        "Though",
        "due to",
        "Due to",
        "owing to the fact that",
        "Owing to the fact that",
        "since",
        "Since",
        "even if",
        "Even if",
        "if",
        "If",
        "as a result of",
        "As a result of",
        "because of",
        "Because of",
        "as a result",
        "As a result",
        "even yet",
        "Even yet",
        "consequently",
        "Consequently",
        "while",
        "While",
        "but",
        "But",
        "because",
        "Because",
        "although",
        "Although",
        "whether",
        "Whether",
        "whereas",
        "Whereas",
        "even when",
        "Even when",
        "despite",
        "Despite",
    ]

    if keyword in midKeys:
        cause = " ".join(firstPart)
        effect = " ".join(secondPart)
        keylocation = "mid"
        return (cause, effect), keyword, keylocation

        # mixture(firstPart,secondPart)
    elif keyword in startmidKeys:
        if status == "start":
            cause = " ".join(firstPart)
            effect = " ".join(secondPart)
            keylocation = "start"
            return (cause, effect), keyword, keylocation

            # mixture(firstPart,secondPart)
        elif status == "middle":
            effect = " ".join(firstPart)
            cause = " ".join(secondPart)
            keylocation = "mid"
            return (cause, effect), keyword, keylocation


def VpExtractNumpy(sent):
    """Numpy Spacy VERB Phrase Extractor"""
    arr = sentMatrix(sent)
    words = list(arr[0])
    deps = list(arr[1])
    poses = list(arr[2])
    tags = list(arr[3])
    # print(arr)
    a = arr.find("ROOT")
    b = list(np.where(a == 0))[1]
    # print(a)
    # print(b)
    limiters = ["advmod", "auxpass", "aux", "neg", "ROOT"]
    if len(words) >= int(b) + 2:
        postDep = deps[int(b) + 1]
    else:
        postDep = "None"
    myPrep = None
    if postDep == "prep" or postDep == "agent":
        myPrep = words[int(b) + 1]
        verbIndex = int(b) + 1
        word = arr[0][int(b) + 1]
    else:
        verbIndex = int(b)
        word = arr[0][int(b)]
    result = []
    pre = []
    for i in range(verbIndex - 1, -1, -1):
        preword = arr[0][i]
        prepos = arr[2][i]
        predep = arr[1][i]
        # print(preword)
        # print(prepos)
        if predep in limiters:
            pre.append([i])
            # print(pre)
        else:
            break
    # print(pre)
    if pre:
        startPoint = pre[-1][0]
        endPoint = verbIndex + 1
        result.append(words[startPoint:endPoint])
    else:
        result.append([word])
    # print(result)
    if myPrep:
        return " ".join(result[0]), myPrep
    else:
        return " ".join(result[0]), None


def NpExtractNumpy(sent, req):
    """Numpy Spacy Noun Phrase Extractor. The system relies heavily on the Noun Phrase Extractor. This function can find any tag (req) from 3 tag sets in spaCy and locate them in the clause matrix. It uses a tag limiter list and moves backward in the matrix and cuts the noun phrase. It can also move forward if needed, for example in case of noun subjects, it moves forward to the ROOT. It can get all the noun phrases in the clause. It compares them and takes the longest if there is any intersection between lists. It accepts additional instruction for any specific requirement. For example, we excluded direct and indirect objects which are before the ROOT and considered them as part of the noun subject."""

    arr = sentMatrix(sent)
    words = list(arr[0])
    deps = list(arr[1])
    poses = list(arr[2])
    tags = list(arr[3])
    # check if verb has preposition e.g. 'suffer from'

    a = arr.find(req)
    b = list(np.where(a == 0))[1]
    # print(req, b)
    itemList = b.tolist()
    # print(itemList,req)

    rootFind = arr.find("ROOT")
    rootIndex = list(np.where(rootFind == 0))[1]
    myVerb = VpExtractNumpy(sent)[0]
    firstVerbWord = myVerb.split()[0]
    firstVerbWordIndex = words.index(firstVerbWord)
    lastVerbWord = myVerb.split()[-1]
    lastVerbWordIndex = words.index(lastVerbWord)
    notallowedPreword = [","]

    if len(words) >= int(rootIndex) + 2:
        rootNextDep = deps[int(rootIndex) + 1]
    else:
        rootNextDep = "None"

    if rootNextDep == "prep":
        limiters = [
            "neg",
            "predet",
            "pcomp",
            "prt",
            "dobj",
            "advmod",
            "npadvmod",
            "det",
            "amod",
            "cc",
            "conj",
            "compound",
            "poss",
            "nummod",
            "attr",
            "punct",
            "poss",
            "case",
            "pobj",
            "auxpass",
            "relcl",
        ]
    else:
        limiters = [
            "neg",
            "predet",
            "pcomp",
            "prt",
            "dobj",
            "npadvmod",
            "advmod",
            "det",
            "amod",
            "cc",
            "conj",
            "compound",
            "poss",
            "nummod",
            "pobj",
            "attr",
            "prep",
            "punct",
            "poss",
            "case",
            "auxpass",
            "relcl",
        ]

    output = []
    result = []

    # checking the numbers and currencies
    if req == "nmod":
        for idx, item in enumerate(itemList):
            if deps[item + 1] == "nummod":
                itemList[idx] = item + 1
                limiters = ["quantmod", "nmod", "nummod"]

    # check indirect object be after verb not before it because nsubj/nsubjpassive phrase may include pobj
    elif req == "pobj":
        limiters = [
            "advmod",
            "npadvmod",
            "amod",
            "agent",
            "punct",
            "quantmod",
            "compound",
            "nummod",
            "poss",
            "case",
            "attr",
            "appos",
            "det",
        ]
        itemList = [x for x in itemList if int(x) > lastVerbWordIndex]
        if len(itemList) > 1:
            itemList = [max([x for x in itemList if int(x) > lastVerbWordIndex])]
        notallowedPreword = []

    for x in itemList:
        # print(x)
        word = arr[0][x]
        # print(word)
        pre = []
        for i in range(x - 1, -1, -1):
            preword = arr[0][i]
            prepos = arr[2][i]
            predep = arr[1][i]
            # print(preword)
            # print(prepos)
            if (
                predep in limiters
                and predep != "pcomp"
                and predep != "ROOT"
                and preword not in notallowedPreword
            ):
                pre.append([i])
                # print(pre)
            else:
                break
        # print(pre)
        if pre:
            # check the words after nsubj/nsubjpass till root
            if req == "nsubj" or req == "nsubjpass" or req == "csubj":

                startPoint = 0  # pre[-1][0]
                endPoint = firstVerbWordIndex
                result.append((words[startPoint:endPoint], x))
            else:
                startPoint = pre[-1][0]
                endPoint = x + 1
                result.append((words[startPoint:endPoint], x))
        else:
            # check the words after nsubj/nsubjpass till root
            if req == "nsubj" or req == "nsubjpass" or req == "csubj":
                startPoint = 0
                endPoint = firstVerbWordIndex
                result.append((words[startPoint:endPoint], x))
            else:
                result.append(([word], x))

    selected = []

    if result and len(result) > 1:
        res = max(result, key=lambda item: len(item[0]))
        output.append(res)
    elif result and len(result) == 1:
        output.append(result[0])
    else:
        return "None"

    if output and req != "pobj":
        res = " ".join(output[0][0])
        return res
    elif output and req == "pobj":
        res = [(" ".join(x[0]), x[1]) for x in result]
        # res = [x for x in res1]
        return res
    else:
        return None


def adjectExtract(sent, req):
    """Numpy Spacy Adjective Phrase Extractor"""
    arr = sentMatrix(sent)
    words = list(arr[0])
    deps = list(arr[1])
    poses = list(arr[2])
    tags = list(arr[3])
    # print(arr)
    a = arr.find(req)
    b = list(np.where(a == 0))[1]
    # print(b)
    itemList = list(b)

    # limiters = ['npadvmod','amod','advmod','compound','punct','attr','acomp']
    limiters = ["AFX", "CC", "JJ", "NN", "HYPH"]
    output = []
    for x in itemList:
        # print('I am here:',x)
        result = []
        word = arr[0][x]
        # print(word)
        pre = []
        for i in range(x - 1, -1, -1):
            preword = arr[0][i]
            pretag = arr[3][i]
            prepos = arr[2][i]
            predep = arr[1][i]
            # print(preword)
            # print(prepos)
            if pretag in limiters and not pretag.startswith("VB"):
                pre.append([i])
                # print(pre)
            else:
                break
        # print(pre)
        if pre:
            startPoint = pre[-1][0]
            endPoint = x + 1
            result.append(words[startPoint:endPoint])
        else:
            result.append([word])
        selected = []
        if len(result) > 1:
            res = max(result, key=lambda item: len(item))
            # print(res[0])
            output.append(" ".join(res))
        else:
            output.append(result[0])

    if output:
        res = max(output, key=len)
        # return " ".join(output[0])
        return res
    else:
        return None


def adverbExtract(sent, req):
    """Numpy Spacy Adverbial Phrase Extractor. It checks if adverb has a 'head' dependency and mix them together"""
    arr = sentMatrix(sent)
    words = list(arr[0])
    deps = list(arr[1])
    poses = list(arr[2])
    tags = list(arr[3])
    heads = list(arr[4])
    # print(arr)
    root = words[deps.index("ROOT")]
    # print("ROOT",root)
    a = arr.find(req)
    b = list(np.where(a == 0))[1]
    # print(a)
    itemList = list(b)
    # print(itemList)
    advp = ""
    advps = []
    advHead = False
    for i in itemList:
        rbword = words[i]
        rbhead = heads[i]
        rbworddep = deps[words.index(rbword)]
        rbheadtag = tags[words.index(rbhead)]
        # print(rbword,rbhead,rbheadtag)
        # checks if adverb has a 'head' dependency and it is adverb and not adjective or root, then join them together
        if (
            rbhead != root
            and rbworddep != "relcl"
            and rbheadtag == "RB"
            or rbheadtag == "RBR"
        ):
            advp = i, rbword, rbhead
            advps.append(advp)
        # If the adverb has a head and it is not superlative, so it is an adjective or similar, we set adv location with it

        else:
            if rbword not in advp:
                if rbword != "n't" and rbword != "not" and rbworddep != "relcl":
                    advp = i, rbword
                    advps.append(advp)
    advAction = 0
    result = []
    # print("ADVPS",advps)
    for adv in advps:
        # Keep the adverb for the beginning of the sentence based on its index location with advAction
        if adv[0] == 0 or adv[0] == 1:
            adverb = " ".join(adv[1:])
            advAction = True
            res = advAction, adverb, advHead
            result.append(res)
        else:
            advAction = False
            adverb = " ".join(adv[1:])
            res = advAction, adverb, advHead
            result.append(res)
    # print("HERE",result)
    return result


def sentTagger(sent):
    """Clause Tagger. This function cuts the sentence into different phrases and finds the clause pattern which will be used later to assign rules to them. Almost everything related to the rules is handled here. It finds the adverbs, relative clauses, and provides 6 output which are used in the whole system process: patt = clause pattern, res = clause parts, root = clause root, myPrep = any preposition after the verb, PrepPhrase = prepositional phrases inside the clause, relativeClause = any relative clause inside the clause."""

    arr = sentMatrix(sent)
    words = list(arr[0])
    deps = list(arr[1])
    poses = list(arr[2])
    tags = list(arr[3])
    a = arr.find("ROOT")
    b = list(np.where(a == 0))[1]
    rootIndex = int(b)
    root = words[rootIndex]
    findVerb = VpExtractNumpy(sent)
    vbPhrase = findVerb[0]
    myPrep = findVerb[1]
    npIndicators = [
        "nsubj",
        "nsubjpass",
        "dobj",
        "pobj",
        "attr",
        "oprd",
        "appos",
        "expl",
        "nmod",
        "xcomp",
        "csubj",
    ]
    result = []
    parts = []
    npSubject = [
        NpExtractNumpy(sent, x)
        for x in arr[1]
        if x in npIndicators and x == "nsubj" or x == "csubj"
    ]
    npPsubject = [
        NpExtractNumpy(sent, x)
        for x in arr[1]
        if x in npIndicators and x == "nsubjpass"
    ]
    npDobject = [
        NpExtractNumpy(sent, x)
        for x in arr[1]
        if x in npIndicators and x == "dobj" or x == "xcomp"
    ]
    npPobjects = [
        NpExtractNumpy(sent, x) for x in arr[1] if x in npIndicators and x == "pobj"
    ]
    npOpr = [
        NpExtractNumpy(sent, x) for x in arr[1] if x in npIndicators and x == "oprd"
    ]
    npAttr = [
        NpExtractNumpy(sent, x) for x in arr[1] if x in npIndicators and x == "attr"
    ]
    npAppos = [
        NpExtractNumpy(sent, x) for x in arr[1] if x in npIndicators and x == "appos"
    ]
    npExpl = [
        NpExtractNumpy(sent, x) for x in arr[1] if x in npIndicators and x == "expl"
    ]
    npNmod = [
        NpExtractNumpy(sent, x) for x in arr[1] if x in npIndicators and x == "nmod"
    ]

    # Find the relative clause and cut the sentence till the end. Only if its index is larger than root.
    # Relative clauses before root are taken in the noun subject extraction instead.
    relatives = ["TO", "WDT", "WD", "WRB"]
    rel = False
    relClause = None
    for r in relatives:
        if r in tags:
            rel = True
            rlocate = arr.find(r)
            rlocation = list(np.where(rlocate == 0))[1]
            rIndex = int(rlocation[0])
            if rIndex > rootIndex:
                rWords = words[rIndex:]
                relClause = " ".join((rWords))
                words = words[:rIndex]
                deps = deps[:rIndex]
                poses = poses[:rIndex]
                tags = tags[:rIndex]
                sent = " ".join(words)

    # It receives a list of dobj from noun extractor, and dobj before root is treated as prepositional phrase
    npPobject = []
    npPrep = []
    if npPobjects and npPobjects[0] != "None":
        for a in npPobjects[-1]:
            if a[1] > rootIndex:
                npPobject.append(a[0])
            else:
                if (npSubject and a[0] not in npSubject[0]) or (
                    npPsubject and a[0] not in npPsubject[0]
                ):
                    npPrep.append(a[0])

    adjectives = []
    if "acomp" in arr[1]:
        adjects = adjectExtract(sent, "acomp")
        if adjects:
            adjectives.append(adjects)
    elif "ccomp" in arr[1]:
        adjects = adjectExtract(sent, "ccomp")
        if adjects:
            adjectives.append(adjects)

    adverbs = []
    if "npadvmod" in arr[1]:
        adverb = adverbExtract(sent, "RB")
        if adverb:
            adverbs.append(adverb)
    elif "advmod" in arr[1]:
        adverb = adverbExtract(sent, "RB")
        if adverb:
            adverbs.append(adverb)

    if npSubject:
        mytag1 = "NP"  #'NP-Subject'
        parts.append(npSubject[0])
        result.append(mytag1)
    if npPsubject:
        mytag2 = "NPP"  #'NP-SubjectPassive'
        parts.append(npPsubject[0])
        result.append(mytag2)

    if not npSubject and not npPsubject:
        npSubject = " ".join(words[:rootIndex])
        mytag1 = "NP"  #'NP-Subject'
        parts.append(npSubject)
        result.append(mytag1)

    if npExpl:
        mytag3 = "NPTH"
        parts.append(npExpl[0])
        result.append(mytag3)
    if vbPhrase:
        mytag4 = "VP"  #'VP-Phrase'
        parts.append(vbPhrase)
        result.append(mytag4)
    if adjectives:
        mytag5 = "ADJP"
        parts.append(adjectives[0])
        result.append(mytag5)
    if npOpr:
        mytag10 = "OBPRD"
        parts.append(npOpr[0])
        result.append(mytag10)
    if npDobject:
        mytag6 = "OBD"  #'NP-Dobject'
        parts.append(npDobject[0])
        result.append(mytag6)
    if npPobject:
        mytag7 = "OBI"  #'NP-Pobject'
        if len(npPobject) > 1:  # if there are many pobj, just join them in a string
            pobjres = " ".join(npPobject)
            parts.append(pobjres)
            result.append(mytag7)
        else:
            parts.append(npPobject[0])
            result.append(mytag7)
    if npAttr:
        mytag8 = "NPAtt"  #'NP-Attr'
        if npPobject and " ".join(npAttr[0]) in " ".join(npPobject[0]):
            pass
        else:
            parts.append(npAttr[0])
            result.append(mytag8)
    if npNmod:
        mytag9 = "ADJNM"
        parts.append(npNmod[0])
        result.append(mytag9)
    if npAppos:
        mytag11 = "OBAPPOS"
        parts.append(npAppos[0])
        # result.append(mytag11)
    if adverbs:
        # check if adverb is not included in adjective phrase before
        if adjectives and adverbs[0] not in adjectives[0]:
            mytag12 = "ADVP"
            parts.append(adverbs[0])
            # result.append(mytag12)
        else:
            mytag12 = "ADVP"
            parts.append(adverbs[0])
            # result.append(mytag12)

    zipRes = [(x, y) for x, y in zip(parts, result) if x != "None"]
    res = [x[0] for x in zipRes]
    patt = [x[1] for x in zipRes]

    # include adjnm in the indirect object if they are following each other
    if "OBI-ADJNM" in "-".join(patt):
        obiIndex = patt.index("OBI")
        adjnmIndex = patt.index("ADJNM")
        mixedRes = res[obiIndex] + " " + res[adjnmIndex]
        res[obiIndex] = mixedRes
        res.pop(adjnmIndex)  # Remove ADJNM string from res
        patt.pop(adjnmIndex)  # Remove ADJNM from patterns

    # Mix OBD and OBI if they have intersection and get the longest as the direct object
    if "OBD" in patt and "OBI" in patt:
        if res[patt.index("OBD")] in res[patt.index("OBI")]:
            obdIndex = patt.index("OBD")
            obiIndex = patt.index("OBI")
            patt.pop(obiIndex)  # remove OBI pattern from patt
            res.pop(obdIndex)  # remove OBD string from res
        else:
            pass

    # First pobj is considered as prepositional phrase to remain in its place
    if npPrep:
        PrepPhrase = npPrep[0]
    else:
        PrepPhrase = None

    # If there are both NPP and NP in the sentence and they are exactly the same, remove NPP and keep NP. This happens because of relative clauses in the noun subject
    if "NP" in patt and "NPP" in patt:
        if res[patt.index("NP")] == res[patt.index("NPP")]:
            npIndex = patt.index("NP")
            nppIndex = patt.index("NPP")
            patt.pop(nppIndex)  # remove NPP from patt
            res.pop(nppIndex)  # remove NPP string from res

    # If there is relative clause, return it
    if rel:
        relativeClause = relClause
    else:
        relativeClause = None

    # If OBI is the last item in patts and there is no relative clause, take everything till the end of the sentence as OBI
    if "-".join(patt) == "NP-VP-OBI" and not relativeClause:
        vpwords = res[1].split()
        vplastwordindex = words.index(vpwords[-1])
        vplastworddep = deps[words.index(vpwords[-1])]
        if vplastworddep == "prep":
            mylastverbIndex = vplastwordindex
        else:
            mylastverbIndex = vplastwordindex + 1
        if vplastwordindex < len(words):
            myRemained = words[mylastverbIndex:]
            res[2] = myRemained
            res[2] = " ".join(res[2])

    elif "-".join(patt) == "NPP-VP-OBI" and not relativeClause:
        vpwords = res[1].split()
        vplastwordindex = words.index(vpwords[-1])
        vplastworddep = deps[words.index(vpwords[-1])]
        if vplastworddep == "prep":
            mylastverbIndex = vplastwordindex
        else:
            mylastverbIndex = vplastwordindex + 1
        if vplastwordindex < len(words):
            myRemained = words[mylastverbIndex:]
            res[2] = myRemained
            res[2] = " ".join(res[2])

    # If OBI is the last item in patts and there is no relative clause, take everything till the end of the sentence as OBI

    if patt[-1] == "OBD" and not relativeClause:
        resLastWord = res[-1].split()
        resLastIndex = words.index(resLastWord[-1])
        if resLastIndex < len(words):
            myRemained = words[resLastIndex + 1 :]
            res[-1] = [res[-1]] + myRemained
            res[-1] = " ".join(res[-1])

    if "-".join(patt) == "NP-VP-ADJP-OBD" and not relativeClause:
        adjwords = " ".join(res[2])
        adjlastwordindex = words.index(adjwords)
        if adjlastwordindex < len(words):
            myRemained = words[adjlastwordindex + 1 :]
            res[3] = myRemained
            res[3] = " ".join(res[3])

    return patt, res, root, myPrep, PrepPhrase, relativeClause


def moveAdeverb(sent, word, position):
    """This function moves the adverbs like "however" to the beginning of the sentence."""
    split = sentMatrix(sent)
    split = split.tolist()[0]
    wordsplit = word.split()

    if word not in sent:
        if word in split:
            split.insert(position, split.pop(split.index(word.lower())))
        else:
            split.insert(position, word)
            split.insert(1, ",")
    else:
        lastword = wordsplit[-1]
        lastwordIndex = split.index(lastword)
        nextwordIndex = lastwordIndex + 1
        if split[nextwordIndex] != ",":
            split.insert(nextwordIndex, ",")

    res = " ".join(split)
    res = res[0].upper() + res[1:]
    return res


def webColoring(sentence, res, res2, res3, posConversion, key):
    if type(posConversion) is list:
        posConversion = posConversion[0]
    else:
        pass

    poses = [(key, value) for key, value in posConversion.items() if key != None]
    enum_poses = [(x[0], x[1][0], x[1][1]) for x in enumerate(poses)]

    keypatt = "<span class='keyWord'><b>{}</b></span>".format(key)
    sentence = sentence.replace(key, keypatt)

    keyUpper = key[0].upper() + key[1:]
    keypatt2 = "<span class='keyWord'><b>{}</b></span>".format(keyUpper)
    sentence = sentence.replace(keyUpper, keypatt2)

    for x in enum_poses:
        sent = ""
        patt = "<span class='converted{}'>{}</span>".format(x[0], x[1])
        sent = sentence.replace(x[1], patt)
        sentence = sent
    for x in enum_poses:
        if x[2] in res:
            res1 = ""
            patt = "<span class='converted{}'>{}</span>".format(x[0], x[2])
            res1 = res.replace(x[2], patt)
            res = res1
    myres2 = res2.split()
    for x in enum_poses:
        if x[2] in res2:
            mywords = [w for w in myres2 if x[2] in w]
            if mywords:
                word = mywords[0]
            else:
                word = x[2]
            resTwo = ""
            patt = "<span class='converted{}'>{}</span>".format(x[0], word)
            resTwo = res2.replace(word, patt)
            res2 = resTwo
        elif x[1] in res2:
            mywords = [w for w in myres2 if x[1] in w]
            if mywords:
                word = mywords[0]
            else:
                word = x[1]
            resTwoR = ""
            patt = "<span class='converted{}'>{}</span>".format(x[0], word)
            resTwoR = res2.replace(word, patt)
            res2 = resTwoR

    for x in enum_poses:
        if x[2] in res3:
            resThree = ""
            patt = "<span class='converted{}'>{}</span>".format(x[0], x[2])
            resThree = res3.replace(x[2], patt)
            res3 = resThree

    return sentence, res, res2, res3


def replacePronoun(sent):
    """ Replacing the Noun Subject and Noun Subject Passive PRONOUNS. """
    engPOSPR = {
        "i": "my",
        "you": "your",
        "he": "his",
        "she": "her",
        "it": "its",
        "we": "our",
        "they": "their",
        "this": "its",
        "that": "its",
        "these": "their",
        "those": "their",
    }
    mtx = sentMatrix(sent)
    # print(mtx)
    subjfind = mtx.find("nsubj")
    subjectIndex = list(np.where(subjfind == 0))[1]
    subjpassfind = mtx.find("nsubjpass")
    subjectpassIndex = list(np.where(subjpassfind == 0))[1]
    markfind = mtx.find("mark")
    markIndex = list(np.where(markfind == 0))[1]
    # print(markIndex)
    if mtx[3][int(subjectIndex)] == "PRP" or mtx[3][int(subjectpassIndex)] == "PRP":
        prfind = mtx.find("PRON")
        pronounsIndex = list(np.where(prfind == 0))[1]
        nounfind = mtx.find("NN")
        nounsIndex = list(np.where(nounfind == 0))[1]
        compoundList = zip(pronounsIndex, nounsIndex)
        pairs = [x for x in compoundList]
        for myIndexes in pairs:
            myfirstWord = mtx[0][myIndexes[0]]
            mysecondWord = mtx[0][myIndexes[1]]
            # print(myIndexes, myfirstWord, mysecondWord)
            mysent = mtx[0]
            mysent[myIndexes[0]] = mysecondWord
            mysent[myIndexes[1]] = engPOSPR.get(myfirstWord.lower())
            if mysent[myIndexes[1] + 1] == "'s":
                mysent[myIndexes[1] + 1] = ""
            res = " ".join(mysent)
            res = res.replace("  ", " ")
            return res
    else:
        return None


def sentCleaner(res):
    """ Part of Cause Sentence Generator """
    # make new sentences and return
    res1 = res.replace("None", "")
    res1 = re.sub(" +", " ", res1)
    res1 = res1.replace("the have of ", "having ")
    res1 = res1.replace("The have of ", "Having ")
    res1 = res1.replace("have of an ", " ")
    res1 = res1.replace("have of a ", " ")
    res1 = res1.replace("have of ", " ")
    res1 = res1.replace("being of ", "being ")
    res1 = res1.replace("the being of ", " ")
    res1 = res1.replace("The being of ", "")
    res1 = res1.replace("'s being ", " to be ")
    res1 = res1.replace("the the", "the")
    res1 = res1.replace(" do of the", " ")
    res1 = res1.replace(" the it ", " it ")
    res1 = res1.replace(" the a ", " a ")
    res1 = res1.replace("s's", "s'")
    res1 = res1.replace(" i ", " I ")
    res1 = res1.replace(" not being OF not ", " not being ")
    res1 = res1.replace(" OF of ", " ")
    res1 = res1.replace(" OF ", " ")
    res1 = res1.replace(" of of ", " of ")
    res1 = res1.replace(" my the ", " my ")
    res1 = res1.replace(" your the ", " your ")
    res1 = res1.replace(" his the ", " his ")
    res1 = res1.replace(" her the ", " her ")
    res1 = res1.replace(" its the ", " its ")
    res1 = res1.replace(" our the ", " our ")
    res1 = res1.replace(" their the ", " their ")
    res1 = res1.replace(" the my ", " my ")
    res1 = res1.replace(" the your ", " your ")
    res1 = res1.replace(" the him ", " him ")
    res1 = res1.replace(" the his ", " his ")
    res1 = res1.replace(" the her ", " her ")
    res1 = res1.replace(" the its ", " its ")
    res1 = res1.replace(" the our ", " our ")
    res1 = res1.replace(" the their ", " their ")
    res1 = res1.replace(" the them ", " them ")

    if res1.endswith("by"):
        res1 = res1.strip("by")
    elif res1.endswith(" by."):
        res1 = res1.strip(" by.")
    res1 = " ".join(res1.split())
    res1 = res1.replace(" ,", ",")
    res1 = res1.replace(" .", ".")
    res1 = res1.strip()
    res1 = re.sub(" +", " ", res1)

    # remove cases like 'its a commercial side' for 'it has a commercial side'
    resMatrix = sentMatrix(res1)
    words = resMatrix[0].tolist()
    deps = resMatrix[1].tolist()
    for x in deps:
        xIndex = deps.index(x)
        nexttag = xIndex + 1
        if x == "poss" and deps[nexttag] == "det":
            words.pop(nexttag)
            res1 = " ".join(words)
    return res1


def conditionalSent(sent):
    """Conditional Sentence Processing"""
    times = []
    sentmtx = sentMatrix(sent)
    # print(sentmtx)
    sentres = checkCause(sent)
    # cut sentence into two causative part
    firstPart = sentres[0][0]
    secondPart = sentres[0][1]
    # get the times for each part
    firstTime = sentTime(firstPart)
    secondTime = sentTime(secondPart)
    times.append(firstTime[1])
    times.append(secondTime[1])
    # make a pattern for conditional types
    mixPattern = "-".join(times)
    # print(mixPattern)
    # find the auxilaries
    auxList = ["'ll", "will", "would", "could", "should", "may"]
    firstAuxFind = [x for x in firstPart.split() if x in auxList]
    secondAuxFind = [x for x in secondPart.split() if x in auxList]

    # nominalize parts
    firstNom = Clause(firstPart, "C").getResult()
    secondNom = Clause(secondPart, "E").getResult()
    # print(firstNom,'\n',secondNom)

    # assign type to conditional sentence
    if mixPattern == "present-present" and not firstAuxFind and not secondAuxFind:
        condType = "0"
        cause = firstNom[0]
        cause = cause[0].upper() + cause[1:]
        sent = "<span class='causePart'> {} </span> will result in <span class='effectPart'> {} </span>".format(
            cause, secondNom[0]
        )
    elif (
        mixPattern == "past-present"
        and secondAuxFind
        and (
            "has" in secondPart.split()
            or "have" in secondPart.split()
            or "had" in secondPart.split()
        )
    ):
        condType = "3"
        cause = firstNom[0]
        cause = cause[0].upper() + cause[1:]
        sent = "<span class='causePart'> {} {} </span> result in <span class='effectPart'> {} </span>".format(
            cause, secondAuxFind[0], secondNom[0]
        )
    elif mixPattern == "past-present" and secondAuxFind:
        condType = "2"
        cause = firstNom[0]
        cause = cause[0].upper() + cause[1:]
        sent = "<span class='causePart'> {} {} </span> result in <span class='effectPart'> {} </span>".format(
            cause, secondAuxFind[0], secondNom[0]
        )
    elif mixPattern == "present-future" and secondAuxFind:
        condType = "1"
        cause = firstNom[0]
        cause = cause[0].upper() + cause[1:]
        sent = "<span class='causePart'> {} </span> will result in <span class='effectPart'> {} </span>".format(
            cause, secondNom[0]
        )
    else:
        condType = "3"
        cause = firstNom[0]
        cause = cause[0].upper() + cause[1:]
        sent = "<span class='causePart'> {} </span> would result in <span class='effectPart'> {} </span>".format(
            cause, secondNom[0]
        )

    sent = sentCleaner(sent)
    return sent


def causativeSent(sent, cause, effect, c, e, p, r):
    if p:
        p = sentCleaner(p)
    effect = sentCleaner(effect)
    cause = sentCleaner(cause)
    c = sentCleaner(c)
    e = sentCleaner(e)

    res4 = "{} caused {}".format(c, e)

    time = expressionTime(effect)
    if time == "past":
        relword1 = "<select><option selected>caused</option><option>led to</option><option>resulted in</option></select>"
        relword2 = "<select><option selected>was a result of </option><option>was caused by</option><option>was due to</option><option>was attributable to</option></select>"
    elif time == "present" or time == "third":
        relword1 = "<select><option selected>causes</option><option>leads to</option><option>results in</option></select>"
        relword2 = "<select><option selected>is a result of </option><option>is caused by</option><option>is due to</option><option>is attributable to</option></select>"
    elif time == "future":
        relword1 = "<select><option selected>will cause</option><option>will lead to</option><option>will result in</option></select>"
        relword2 = "<select><option selected>will be a result of </option><option>will be caused by</option><option>will be due to</option><option>will be attributable to</option></select>"
    else:
        relword1 = "<select><option selected>caused</option><option>led to</option><option>resulted in</option></select>"
        relword2 = "<select><option selected>was a result of </option><option>was caused by</option><option>was due to</option><option>was attributable to</option></select>"

    if r[0] == True:
        relKeyword = "because"
    else:
        relKeyword = "because of"

    """ This part handles the first type of causative output sentence"""
    # c = c[0].upper()+c[1:]
    c1 = c[0].upper() + c[1:]
    res = "<span class='causePart'> <span class='tooltiptext'>Cause Clause</span> {} {} </span> {} <span class='effectPart'> <span class='tooltiptext'>Effect Clause</span> {} </span>.".format(
        p, c1, relword1, e
    )
    res = res.replace(" None ", "")

    """ This part handles the second type of causative output sentence"""
    effect = effect[0].upper() + effect[1:]
    # c = c[0].lower()+c[1:]
    res2 = "<span class='effectPart'> <span class='tooltiptext'>Effect Clause</span> {} {} </span> {} <span class='causePart'> <span class='tooltiptext'>Cause Clause</span> {} </span>.".format(
        p, effect, relKeyword, c
    )
    res2 = res2.replace("None", "")

    """ This part handles the third type of causative output sentence"""
    e = e[0].upper() + e[1:]
    # c = c[0].lower()+c[1:]
    res3 = "<span class='effectPart'> <span class='tooltiptext'>Effect Clause</span> {} {} </span> {} <span class='causePart'> <span class='tooltiptext'>Cause Clause</span> {} </span>.".format(
        p, e, relword2, c
    )
    res3 = res3.replace(" None ", "")

    return res, res2, res3, res4


def temporalSent(sent, cause, effect, c, e, p, key, location):
    if p:
        p = sentCleaner(p)
    cause = sentCleaner(cause)
    effect = sentCleaner(effect)
    c = sentCleaner(c)
    e = sentCleaner(e)

    res4 = "{} key {}".format(c, e)

    effect = effect[0].upper() + effect[1:]
    res = "<span class='effectPart'><span class='tooltiptext'>Main Clause</span> {} </span> <b> {} </b> <span class='causePart'><span class='tooltiptext'>Subordinate Clause</span> {} </span>".format(
        effect, key, c
    )
    res = res.replace(" None ", "")

    res2 = "<span></span>"
    res3 = "<span></span>"

    return res, res2, res3, res4


def concessSent(sent, cause, effect, c, e, p):
    if p:
        p = sentCleaner(p)
    cause = sentCleaner(cause)
    effect = sentCleaner(effect)
    c = sentCleaner(c)
    e = sentCleaner(e)

    res4 = "{} despite {}".format(e, c)

    time = expressionTime(effect)
    if time == "past":
        relword = "<select><option selected>was in spite of </option><option> was despite</option></select>"
    elif time == "present" or time == "third":
        relword = "<select><option selected>is in spite of </option><option>is despite</option></select>"
    elif time == "future":
        relword = "<select><option selected>will be in spite of </option><option> will be despite</option></select>"
    else:
        relword = "<select><option selected>was in spite of </option><option>was despite</option></select>"

    """ This part handles the two types of concessive output sentence"""
    e1 = e[0].upper() + e[1:]
    # c = c[0].lower()+c[1:]
    res = "<span class='effectPart'><span class='tooltiptext'>Effect Clause</span> {} {} </span> {} <span class='causePart'><span class='tooltiptext'>Calim Clause</span>  {} </span>.".format(
        p, e1, relword, c
    )
    res = res.replace(" None ", "")

    effect = effect[0].upper() + effect[1:]
    # c = c[0].lower()+c[1:]
    """ This part handles the second type of concessive output sentence"""
    res2 = "<span class='effectPart'><span class='tooltiptext'>Effect Clause</span> {} {} </span> despite <span class='causePart'><span class='tooltiptext'>Claim Clause</span>  {} </span>.".format(
        p, effect, c
    )
    res2 = res2.replace(" None ", "")

    # res2 = "<span></span>"
    res3 = "<span></span>"

    return res, res2, res3, res4


def cline(sentence):
    # """Main Method to Run the Program and Output Sentence Generator"""
    # try:
    # sentence1 = re.sub(',', '', sentence)
    if ";" in sentence:
        sep = ";"
        sentence = sentence.split(sep, 1)[0]

    clauses = []
    matrix1 = sentMatrix(sentence)
    if matrix1[1][-1] == "punct":
        sent = matrix1[0]
        sent = sent[:-1]
        sent = " ".join(sent)
    else:
        sent = sentence

    """Cause check"""
    sentres = checkCause(sent)

    concessKeys = ["though", "although", "even though", "despite", "in spite of", "but"]
    temporalKeys = ["after", "before", "until", "once"]
    concess = False
    conditional = False
    temporal = False

    if sentres:
        cause = True
        """Concession check"""
        key = sentres[1]
        keylocation = sentres[2]
        if key in concessKeys and keylocation == "start":
            concess = True
        elif key in concessKeys and keylocation == "mid" and key != "but":
            concess = True
            # cause = False
        elif key in concessKeys and keylocation == "mid" and key == "but":
            concess = True
        """End Concession"""

        """Temporal check"""
        if key in temporalKeys:
            temporal = True
            concess = False
            templocation = keylocation
        """End Temporal"""

        """ Check Conditional"""
        if key == "if" and keylocation == "start":
            conditional = True
            cause = True
            concess = False
        """End Conditional"""

        for res in sentres[0]:
            clauses.append([res.strip(",")])
    else:
        cause = False
        sentres = clausekit(sent)
        for res in sentres:
            clauses.append([res.strip(",")])

    result = []
    causePart = []
    prepPhrase = []
    effectPart = []
    clauseCases = []
    clauseErrors = []
    # posConversion = []
    initAdverb = []
    relCheck = []
    moveRes = ""
    participlePhrase = []
    causePOSConversion = []  # specifically for web coloring the Res2
    effectPOSConversion = []
    notFormattedResult = []  # Clean Result without formatting

    errors = {
        101: "No subject",
        102: "No passive subject",
        103: "Incorrect Parsing",
        104: "NP+BE Clause",
        105: "Unknown Structure",
        107: "Modal verb",
    }
    if cause == True:
        c = None
        e = None
        # c_pos = ''
        # e_pos = ''

        if len(clauses[0][0].split()) > 1:
            c = Clause(clauses[0][0], "C").getResult()
            # print(c)
            causePart.append(c[0])
            clauseCases.append(c[1])
            clauseErrors.append(c[2])
            c_pos = c[3]
            causePOSConversion.append(c[3])
            prepPhrase.append(c[4])
            initAdverb.append(c[5])
            relCheck.append(c[6])
        else:
            causePart.append(clauses[0][0])

        if len(clauses[1][0].split()) > 1:
            e = Clause(clauses[1][0], "E").getResult()
            # print(e)
            effectPart.append(e[0])
            clauseCases.append(e[1])
            clauseErrors.append(e[2])
            e_pos = e[3]
            effectPOSConversion.append(e[3])
            prepPhrase.append(e[4])
            initAdverb.append(e[5])
            relCheck.append(e[6])
            participlePhrase.append(e[7])
        else:
            effectPart.append(clauses[1][0])

        if c_pos and e_pos:
            posConversion = {**c_pos, **e_pos}
        else:
            posConversion = {}

        sen_time = sentTime(sent)
        moveRes = moveTable(
            (clauses[0][0], c), (clauses[1][0], e), key, participlePhrase, sen_time
        )  #### MOVEMENT TABLE STARTS HERE
    else:
        ############################################################################################################
        cCheck = checkCausative(sentence)
        sen_time = expressionTime(sent)
        if cCheck:
            # print(cCheck)
            firstPart = cCheck[0]
            secPart = cCheck[1]
            # print("hereeeee", firstPart, "******",secPart,"*****",sen_time)
            firstExp = Expression(firstPart, sen_time).cleaned()
            secExp = Expression(secPart, sen_time).cleaned()
            newSent = "{} so {}".format(firstExp, secExp)
            # print(newSent)
            if newSent:
                res4 = cline(newSent)
                return res4
            #######################################################################################################
        else:
            # if there is a sentence, we produce its nomialized phrase here. "she was fired" as input to "her fire"
            resShort = Clause(sentence, "C").getResult()
            if resShort:
                res = resShort[0]
                res = sentCleaner(res)
            else:
                res = "{}".format(sentence)
            res2 = "Skipped"
            posConversion = "None"
            webColor = []
            prChange = []
            clauseErrors = [106, "Not Causative"]
            moveRes = []
            return (
                res,
                res2,
                posConversion,
                clauseCases,
                clauseErrors,
                webColor,
                prChange,
                moveRes,
                notFormattedResult,
            )

    if cause == True and not any(
        x in [101, 102, 103, 104, 105, 107] for x in clauseErrors
    ):
        effectLower = effectPart[0][0].lower() + effectPart[0][1:]
        sen_time = sentTime(sent)
        sent_time = sen_time[0]
        mytime = sen_time[1]

        # Find a verb for Concessive 1st type sentence
        if mytime == "present":
            myverb = "is"
        elif mytime == "past":
            myverb = "was"
        elif mytime == "future":
            myverb = "will be"

        # Handles Causative Result Generation
        if concess == False:
            """ This part handles the 3 types of causative output sentences"""
            cause_res = causativeSent(
                sent,
                clauses[0][0],
                clauses[1][0],
                causePart[0],
                effectPart[0],
                prepPhrase[0],
                relCheck,
            )
            # print("RES",cause_res)
            res = cause_res[0]
            res2 = cause_res[1]
            res3 = cause_res[2]
            res4 = cause_res[3]
            notFormattedResult.append(res4)

        # Handles Concessive Result Generation
        elif concess == True:
            concess_res = concessSent(
                sent,
                clauses[0][0],
                clauses[1][0],
                causePart[0],
                effectPart[0],
                prepPhrase[0],
            )
            res = concess_res[0]
            res2 = concess_res[1]
            res3 = concess_res[2]
            res4 = concess_res[3]
            notFormattedResult.append(res4)

        if temporal == True:
            temp_res = temporalSent(
                sent,
                clauses[0][0],
                clauses[1][0],
                causePart[0],
                effectPart[0],
                prepPhrase[0],
                key,
                templocation,
            )
            res = temp_res[0]
            res2 = temp_res[1]
            res3 = temp_res[2]
            res4 = temp_res[3]
            notFormattedResult.append(res4)

        if conditional == True:
            res = conditionalSent(sent)
            res = sentCleaner(res)
            res2 = conditionalSent(sent)
            res2 = sentCleaner(res2)
            res3 = res2
            notFormattedResult.append(res2)

        """ This part checks and returns the adverbs"""
        if initAdverb:
            myadverb = [x for x in initAdverb if x != None]
            if myadverb:
                # myadverbIndex = list(matrix1[3]).index('RB')
                # myadverb = matrix1[0][myadverbIndex].lower()
                myadverb = " ".join(myadverb)
                mysent = res
                poisition = 0
                res = moveAdeverb(mysent, myadverb, 0)
                res2 = moveAdeverb(res2, myadverb, 0)
                res = res.replace(" ,", ",")
                res2 = res2.replace(" ,", ",")
                res3 = res3.replace(" ,", ",")
                """ Extra Web Work for Res2 output """
                webColor = webColoring(
                    sentence, res, res2, res3, causePOSConversion, key
                )
                prChange = []  # replacePronoun(res2)
                return (
                    res,
                    res2,
                    posConversion,
                    clauseCases,
                    clauseErrors,
                    webColor,
                    prChange,
                    moveRes,
                    notFormattedResult,
                )
            else:
                res = res[0].upper() + res[1:]
                res2 = res2[0].upper() + res2[1:]
                res3 = res3[0].upper() + res3[1:]
                """ Extra Web Work for Res2 output """
                webColor = webColoring(sentence, res, res2, res3, posConversion, key)
                prChange = []  # replacePronoun(res2)
                return (
                    res,
                    res2,
                    posConversion,
                    clauseCases,
                    clauseErrors,
                    webColor,
                    prChange,
                    moveRes,
                    notFormattedResult,
                )
        else:
            res = res[0].upper() + res[1:]
            res2 = res2[0].upper() + res2[1:]
            res3 = res3[0].upper() + res3[1:]
            """ Extra Web Work for Res2 output """
            webColor = webColoring(sentence, res, res2, res3, posConversion, key)
            prChange = []  # replacePronoun(res2)
            return (
                res,
                res2,
                posConversion,
                clauseCases,
                clauseErrors,
                webColor,
                prChange,
                moveRes,
                notFormattedResult,
            )

    else:
        error = [x for x in clauseErrors if x in [101, 102, 103, 104, 105, 107]]
        res2 = "Skipped"
        posConversion = "None"
        webColor = []
        prChange = []
        moveRes = []
        notFormattedResult = []
        return (
            sentence,
            res2,
            posConversion,
            clauseCases,
            clauseErrors,
            webColor,
            prChange,
            moveRes,
            notFormattedResult,
        )


# except Exception as e:
# print(e)
# """If this function gets an exception for any reason, an error code '110' will be generated """
# res = '{} * Error {}'.format(sentence,e)
# res2 = "Error"
# posConversion = []
# clauseCases = []
# webColor = []
# prChange = []
# clauseErrors = [110,"Fatal Error"]
# moveRes = []
# notFormattedResult = []
# return sentence,res2,posConversion,clauseCases,clauseErrors,webColor,prChange,moveRes,notFormattedResult


def clineNoEffect(sentence):
    """Main Method to Run the Program and Output Sentence Generator"""
    try:
        # sentence1 = re.sub(',', '', sentence)
        if ";" in sentence:
            sep = ";"
            sentence = sentence.split(sep, 1)[0]
        clauses = []
        matrix1 = sentMatrix(sentence)
        if matrix1[1][-1] == "punct":
            sent = matrix1[0]
            sent = sent[:-1]
            sent = " ".join(sent)
        else:
            sent = sentence

        """Cause check"""
        sentres = checkCause(sent)

        concessKeys = [
            "though",
            "although",
            "even though",
            "despite",
            "in spite of",
            "but",
        ]
        concess = False
        conditional = False

        if sentres:
            cause = True
            """Concession check"""
            key = sentres[1]
            keylocation = sentres[2]
            if key in concessKeys and keylocation == "start":
                concess = True
            elif key in concessKeys and keylocation == "mid" and key != "but":
                concess = True
                cause = False
            elif key in concessKeys and keylocation == "mid" and key == "but":
                concess = True
            """End Concession"""

            """ Check Conditional"""
            if key == "if" and keylocation == "start":
                conditional = True
                cause = True
                concess = False
            """End Conditional"""

            for res in sentres[0]:
                clauses.append([res.strip(",")])
        else:
            cause = False
            sentres = clausekit(sent)
            for res in sentres:
                clauses.append([res.strip(",")])

        result = []
        causePart = []
        prepPhrase = []
        effectPart = []
        clauseCases = []
        clauseErrors = []
        posConversion = []
        initAdverb = []
        relCheck = []
        causePOSConversion = []  # specifically for web coloring the Res2

        errors = {
            101: "No subject",
            102: "No passive subject",
            103: "Incorrect Parsing",
            104: "NP+BE Clause",
            105: "Unknown Structure",
            107: "Modal verb",
        }
        if cause == True:
            if len(clauses[0][0].split()) > 1 and "VERB" in [
                w.pos_ for w in nlp(clauses[0][0])
            ]:
                c = Clause(clauses[0][0], "C").getResult()
                # print(c)
                causePart.append(c[0])
                clauseCases.append(c[1])
                clauseErrors.append(c[2])
                posConversion.append(c[3])
                causePOSConversion.append(c[3])
                prepPhrase.append(c[4])
                initAdverb.append(c[5])
                relCheck.append(c[6])
            else:
                causePart.append(clauses[0][0])

            # if len(clauses[1][0].split()) > 1 and 'VERB' in [w.pos_ for w in nlp(clauses[1][0])]:
            # e = Clause(clauses[1][0],'E').getResult()
            # print(e)
            # effectPart.append(e[0])
            # clauseCases.append(e[1])
            # clauseErrors.append(e[2])
            # posConversion.append(e[3])
            # prepPhrase.append(e[4])
            # initAdverb.append(e[5])
            # else:
            # effectPart.append(clauses[1][0])

        else:
            res = "{} * Not Cause".format(sentence)
            res2 = "Skipped"
            posConversion = "None"
            webColor = []
            prChange = []
            clauseErrors = [106, "Not Causative"]
            return (
                sentence,
                res2,
                posConversion,
                clauseCases,
                clauseErrors,
                webColor,
                prChange,
            )

        if cause == True and not any(
            x in [101, 102, 103, 104, 105, 107] for x in clauseErrors
        ):
            effectLower = clauses[1][0]
            effectPart = [clauses[1][0]]
            sen_time = sentTime(sent)
            sent_time = sen_time[0]
            mytime = sen_time[1]

            # Find a verb for Concessive 1st type sentence
            if mytime == "present":
                myverb = "is"
            elif mytime == "past":
                myverb = "was"
            elif mytime == "future":
                myverb = "will be"

            # Handles Causative Result Generation
            if concess == False:
                """ This part handles the first type of causative output sentence"""
                res = "{} {} {} {}.".format(
                    prepPhrase[0], causePart[0], sent_time, effectPart[0]
                )
                res = sentCleaner(res)

                if relCheck[0] == True:
                    relKeyword = "because"
                else:
                    relKeyword = "because of"

                """ This part handles the second type of causative output sentence"""
                res2 = "{} {} {} {}.".format(
                    prepPhrase[0], clauses[1][0], relKeyword, causePart[0]
                )
                res2 = sentCleaner(res2)

            # Handles Concessive Result Generation
            else:
                """ This part handles the first type of concessive output sentence"""
                res = "{} {} {} in spite of {}.".format(
                    prepPhrase[0], effectPart[0], myverb, causePart[0]
                )
                res = sentCleaner(res)

                """ This part handles the second type of concessive output sentence"""
                res2 = "{} {} despite {}.".format(
                    prepPhrase[0], clauses[1][0], causePart[0]
                )
                res2 = sentCleaner(res2)

            if conditional == True:
                res = conditionalSent(sent)
                res = sentCleaner(res)
                res2 = conditionalSent(sent)
                res2 = sentCleaner(res2)

            """ This part checks and returns the adverbs"""
            if initAdverb:
                myadverb = [x for x in initAdverb if x != None]
                if myadverb:
                    myadverb = " ".join(myadverb)
                    mysent = res
                    poisition = 0
                    res = moveAdeverb(mysent, myadverb, 0)
                    res2 = moveAdeverb(res2, myadverb, 0)
                    res = res.replace(" ,", ",")
                    res2 = res2.replace(" ,", ",")
                    """ Extra Web Work for Res2 output """
                    webColor = webColoring(sentence, res2, causePOSConversion)
                    prChange = []  # replacePronoun(res2)
                    return (
                        res,
                        res2,
                        posConversion,
                        clauseCases,
                        clauseErrors,
                        webColor,
                        prChange,
                    )
                else:
                    res = res[0].upper() + res[1:]
                    res2 = res2[0].upper() + res2[1:]
                    """ Extra Web Work for Res2 output """
                    webColor = webColoring(sentence, res2, causePOSConversion)
                    prChange = []  # replacePronoun(res2)
                    return (
                        res,
                        res2,
                        posConversion,
                        clauseCases,
                        clauseErrors,
                        webColor,
                        prChange,
                    )
            else:
                res = res[0].upper() + res[1:]
                res2 = res2[0].upper() + res2[1:]
                """ Extra Web Work for Res2 output """
                webColor = webColoring(sentence, res2, causePOSConversion)
                prChange = []  # replacePronoun(res2)
                return (
                    res,
                    res2,
                    posConversion,
                    clauseCases,
                    clauseErrors,
                    webColor,
                    prChange,
                )

        else:
            error = [x for x in clauseErrors if x in [101, 102, 103, 104, 105, 107]]
            res2 = "Skipped"
            posConversion = "None"
            webColor = []
            prChange = []
            return (
                sentence,
                res2,
                posConversion,
                clauseCases,
                clauseErrors,
                webColor,
                prChange,
            )

    except Exception as e:
        # print(e)
        """If this function gets an exception for any reason, an error code '110' will be generated """
        res = "{} * Error {}".format(sentence, e)
        res2 = "Error"
        posConversion = []
        clauseCases = []
        webColor = []
        prChange = []
        clauseErrors = [110, "Fatal Error"]
        return (
            sentence,
            res2,
            posConversion,
            clauseCases,
            clauseErrors,
            webColor,
            prChange,
        )


def moveTable(c, e, k, p, time):
    try:
        key = k
        participlePhrase = p[0]
        keyUpper = k[0].upper() + k[1:]
        cause = c[0]
        causeUpper = cause[0].upper() + cause[1:]
        effect = e[0]
        effectUpper = effect[0].upper() + effect[1:]
        causeRes = c[1][0]
        causeResUpper = causeRes[0].upper() + causeRes[1:]
        effectRes = e[1][0]
        effectResUpper = effectRes[0].upper() + effectRes[1:]

        cause = sentCleaner(cause)
        effect = sentCleaner(effect)
        effectResUpper = sentCleaner(effectResUpper)
        participlePhrase = sentCleaner(participlePhrase)
        effectRes = sentCleaner(effectRes)
        causeResUpper = sentCleaner(causeResUpper)
        causeUpper = sentCleaner(causeUpper)
        causeRes = sentCleaner(causeRes)

        a = "{}. {} {}".format(causeUpper, keyUpper, effect)
        b = "{}; {} {}".format(causeUpper, key, effect)
        c = "Because {}, {}".format(cause, effect)
        d = "{} caused {}".format(causeResUpper, participlePhrase)
        e = "Through {}, {}".format(causeRes, effect)
        f = "{} was due to {} ".format(effectResUpper, causeRes)
        g = "{} caused {}".format(causeResUpper, effectRes)
        h = "The cause of {} was {} ".format(effectRes, causeRes)
        i = "{} through {}".format(effectRes, causeRes)

        return a, b, c, d, e, f, g, h, i
    except:
        return None


def checkCausative(sentence):
    sent = sentence.split()
    causeWords = ["cause", "result", "permit", "help"]
    mtx = sentMatrix(sentence)
    root = mtx[0].tolist()[mtx[1].tolist().index("ROOT")]
    root = nltk.stem.WordNetLemmatizer().lemmatize(root, "v")
    if root in causeWords:
        sentPattern = sentTagger(sentence)[1]
        rootlastWord = sentPattern[1].split()[-1]
        rootlastWordindex = sent.index(rootlastWord)
        secondPart = " ".join(sent[rootlastWordindex + 1 :])
        firstPart = sentPattern[0]
        return (firstPart, secondPart)
    else:
        return None


def caluse_score(clauses, model):
    scores = []
    if model == "bert":
        for clause in clauses:
            score = langmodel.bert_sent_score(clause)
            scores.append(score)
    else:
        for clause in clauses:
            score = langmodel.xlnet_sent_score(clause)
            scores.append(score)
    return scores
