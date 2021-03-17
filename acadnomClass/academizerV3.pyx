#!/usr/bin/env python
# coding: utf-8

import concurrent.futures
import csv
import re
import subprocess
import traceback

import nltk
import numpy as np
import pandas as pd
import stanza

nlp = stanza.Pipeline(lang="en", processors="tokenize,mwt,pos,lemma,depparse")
import spacy

snlp = spacy.load("en_core_web_sm")
import acadnomClass.langmodel as langmodel
import torch
from lemminflect import getInflection
from nltk.stem import WordNetLemmatizer

lemmatizer = WordNetLemmatizer()

stops = [
    "first",
    "moreover",
    "from",
    "give",
    "less",
    "hers",
    "she",
    "when",
    "whoever",
    "empty",
    "in",
    "hereupon",
    "been",
    "each",
    "take",
    "used",
    "whereas",
    "except",
    "which",
    "whereupon",
    "two",
    "within",
    "via",
    "why",
    "beforehand",
    "thence",
    "thereafter",
    "thereupon",
    "whom",
    "ever",
    "front",
    "would",
    "being",
    "else",
    "just",
    "ourselves",
    "after",
    "yours",
    "four",
    "wherein",
    "back",
    "cannot",
    "are",
    "or",
    "bottom",
    "regarding",
    "up",
    "as",
    "off",
    "could",
    "does",
    "somewhere",
    "the",
    "then",
    "whether",
    "another",
    "above",
    "whenever",
    "some",
    "latter",
    "'ll",
    "more",
    "see",
    "name",
    "until",
    "onto",
    "them",
    "along",
    "myself",
    "put",
    "however",
    "show",
    "several",
    "made",
    "him",
    "through",
    "you",
    "mostly",
    "is",
    "last",
    "seemed",
    "these",
    "those",
    "amount",
    "its",
    "further",
    "meanwhile",
    "out",
    "have",
    "everyone",
    "six",
    "various",
    "if",
    "yourself",
    "go",
    "thereby",
    "only",
    "itself",
    "for",
    "nobody",
    "‘s",
    "nothing",
    "anything",
    "'re",
    "anyhow",
    "has",
    "per",
    "against",
    "that",
    "whither",
    "became",
    "doing",
    "whatever",
    "anyway",
    "us",
    "‘ll",
    "now",
    "top",
    "either",
    "using",
    "amongst",
    "full",
    "by",
    "your",
    "‘m",
    "nor",
    "fifteen",
    "any",
    "eleven",
    "about",
    "'s",
    "therefore",
    "hundred",
    "my",
    "this",
    "three",
    "afterwards",
    "anywhere",
    "herein",
    "themselves",
    "sometime",
    "it",
    "third",
    "must",
    "down",
    "nevertheless",
    "seem",
    "seeming",
    "was",
    "everywhere",
    "former",
    "somehow",
    "serious",
    "sometimes",
    "under",
    "he",
    "there",
    "what",
    "something",
    "beside",
    "whole",
    "n't",
    "her",
    "alone",
    "always",
    "herself",
    "whence",
    "can",
    "becoming",
    "rather",
    "whose",
    "ours",
    "everything",
    "whereby",
    "even",
    "they",
    "since",
    "own",
    "all",
    "five",
    "am",
    "his",
    "too",
    "yet",
    "most",
    "how",
    "'ve",
    "twenty",
    "unless",
    "many",
    "quite",
    "none",
    "hereafter",
    "again",
    "perhaps",
    "please",
    "before",
    "nowhere",
    "towards",
    "below",
    "others",
    "whereafter",
    "among",
    "say",
    "wherever",
    "almost",
    "together",
    "’ll",
    "done",
    "neither",
    "an",
    "elsewhere",
    "one",
    "beyond",
    "upon",
    "where",
    "n’t",
    "here",
    "so",
    "twelve",
    "although",
    "had",
    "otherwise",
    "be",
    "behind",
    "indeed",
    "nine",
    "once",
    "re",
    "keep",
    "least",
    "forty",
    "part",
    "do",
    "than",
    "throughout",
    "enough",
    "thru",
    "while",
    "i",
    "’d",
    "’re",
    "between",
    "ca",
    "latterly",
    "did",
    "become",
    "someone",
    "will",
    "yourselves",
    "‘d",
    "‘re",
    "at",
    "call",
    "becomes",
    "himself",
    "really",
    "sixty",
    "well",
    "fifty",
    "who",
    "with",
    "'m",
    "may",
    "mine",
    "much",
    "noone",
    "should",
    "thus",
    "’ve",
    "ten",
    "get",
    "both",
    "our",
    "during",
    "toward",
    "without",
    "‘ve",
    "’s",
    "often",
    "besides",
    "though",
    "such",
    "few",
    "and",
    "’m",
    "across",
    "might",
    "very",
    "other",
    "formerly",
    "their",
    "we",
    "to",
    "next",
    "seems",
    "'d",
    "anyone",
    "me",
    "also",
    "same",
    "side",
    "were",
    "never",
    "over",
    "hereby",
    "into",
    "due",
    "eight",
    "no",
    "therein",
    "namely",
    "a",
    "move",
    "of",
    "on",
    "already",
    "because",
    "but",
    "hence",
    "n‘t",
    "not",
    "around",
    "every",
    "still",
    "am",
    "is",
    "are",
    "be",
    "was",
    "were",
    "have",
    "has",
    "had",
]

hotwords = []

# extracted from Pavlick Human Informal List
"""
checkList = ["the","what",",", "am", "is", "are", "was", "were", "have", "has", "had", "will", "would","could","and","been","you","he","she","dad","daughter","him","her","their","my","our","its","friday","monday","do","did","does","which","thursday","can","could","will","would"]
res = [x for x in longinformList if not any(ext in x for ext in checkList) and not x.startswith("to ") and not x.startswith("of ") and not x.startswith("for ") and not x.startswith("a ") and not x.endswith(" to") and len(x.split())>1 and not x.endswith(" that") and not x.endswith(" of") and not x.endswith("i ")]
removals = []
for x in list(set(res)):
    #print(x)
    a = sentMatrix(x)
    if "NNP" in a[3]:
        removals.append(x)
human_mwes = [x for x in list(set(res)) if x not in removals and x.replace(" ","_") not in mwe_list]
"""
human_mwes = [
    "feel like",
    "throw it",
    "be good for",
    "involved in",
    "in return for",
    "all kinds",
    "very good",
    "fall into",
    "lack of a",
    "old age",
    "be talking about",
    "i thought",
    "i told",
    "some sort",
    "based on",
    "living with",
    "planned for",
    "an opportunity",
    "state in",
    "search for",
    "lawyer in",
    "married in",
    "death squads",
    "far from",
    "live up",
    "lot about",
    "funds for",
    "kind of funny",
    "very strong",
    "points out",
    "deep into",
    "found on",
    "aimed at",
    "received from",
    "information on",
    "in writing",
    "as important",
    "each year",
    "looked like",
    "an apartment",
    "asking for",
    "deals with",
    "open up",
    "be performed",
    "nearly all",
    "not real",
    "in town",
    "end up",
    "new ones",
    "step back",
    "place in",
    "left for",
    "start at",
    "spoke about",
    "engage in",
    "plant in",
    "be changed",
    "hold up",
    "an explanation",
    "looks like a",
    "in place",
    "not prevent",
    "stepped up",
    "know anything",
    "money on",
    "anybody else",
    "common sense",
    "high as",
    "worried about",
    "real nice",
    "as soon",
    "service on",
    "picking up",
    "provide a",
    "in politics",
    "point of view",
    "most basic",
    "comes from",
    "some pretty",
    "i like",
    "not good",
    "be treated",
    "shot dead",
    "that provide",
    "start with",
    "good friend",
    "guided by",
    "available at",
    "good time",
    "hold on",
    "relied on",
    "know how",
    "as an alternative",
    "taking place",
    "character in",
    "half an",
    "set for",
    "get to know",
    "money for",
    "carried out",
    "i wanted",
    "pretty big",
    "turns out",
    "i love it",
    "very little",
    "includes a",
    "little things",
    "several years",
    "more expensive",
    "be submitted by",
    "problem in",
    "turned away",
    "workers in",
    "worked out",
    "very quickly",
    "right away",
    "meeting on",
    "action in",
    "mentioned in",
    "an audience",
    "include a",
    "some things",
    "buy it",
    "chosen by",
    "that country",
    "looking into",
    "any problems",
    "good stuff",
    "group in",
    "way with",
    "movie about",
    "deepest sympathies",
    "make sure",
    "live on",
    "an agent",
    "good enough",
    "statement by",
    "looked at",
    "needs to be",
    "i guess",
    "homeless people",
    "with great",
    "right after",
    "case in",
    "player in",
    "sent out",
    "model for",
    "represents a",
    "presents a",
    "fine with",
    "pretty much",
    "much longer",
    "remind us",
    "i think it",
    "be great",
    "learn from",
    "reach out",
    "law enforcement",
    "some problems",
    "pretty bad",
    "staff member",
    "not include",
    "laid off",
    "an offer",
    "comes up",
    "much bigger",
    "problem for",
    "an impact",
    "turned around",
    "taught in",
    "come back",
    "carrying out",
    "once a year",
    "that offer",
    "chief executive officer",
    "so nice",
    "walked in",
    "grown up",
    "it looks like",
    "live in",
    "in a place",
    "killing of a",
    "looking at",
    "with a big",
    "voted on",
    "office in",
    "more important",
    "stage in",
    "an investment",
    "real good",
    "public affairs",
    "come home",
    "run over",
    "an increase",
    "very difficult",
    "create an",
    "be submitted",
    "negotiate with",
    "i sat",
    "civil service",
    "people from",
    "very important",
    "workers at",
    "not agree",
    "not allowed",
    "really nice",
    "wait a minute",
    "an announcement",
    "problems for",
    "something like a",
    "depends on",
    "suffers from",
    "grab a",
    "removed from",
    "be considered",
    "so far",
    "take place",
    "run at",
    "in dealing with",
    "succeeded in",
    "i saw it",
    "news coverage",
    "in a position",
    "be useful",
    "run it",
    "an appointment",
    "past few",
    "found out",
    "very nice",
    "stay at",
    "as long",
    "hold it",
    "meet with",
    "job in",
    "by far",
    "making progress",
    "come through",
    "fill out",
    "not sure",
    "any real",
    "any case",
    "in a statement",
    "an interest",
    "asked for",
    "in particular",
    "going to come",
    "so funny",
    "setting up",
    "pull out",
    "know if",
    "dealt with",
    "an attempt",
    "ties with",
    "put in place",
    "made sense",
    "talked about",
    "change from",
    "got home",
    "former chief",
    "leave it",
    "kind of a",
    "some kind",
    "buried in",
    "pretty good",
    "at stake",
    "in mind",
    "be based on",
    "some real",
    "be addressed",
    "an answer",
    "really important",
    "creating a",
    "right on",
    "election day",
    "i ended up",
    "go forward",
    "possible for",
    "be found",
    "pointed out",
    "really great",
    "one thing",
    "war between",
    "be involved",
    "engaged in",
    "so long",
    "reported by",
    "pretty close",
    "right for",
    "business leaders",
    "each day",
    "good people",
    "happened in",
    "all right",
    "an end",
    "interests in",
    "it difficult",
    "be based",
    "move forward",
    "set at",
]

academic = open("Dicts/newMappingUnderline2000_POSLemma_Added.txt", "r").readlines()
academicList = [x.strip("\n").split("\t") for x in academic]
print(academicList[0])
mwe_list = [x[4] for x in academicList if x[3] == "MWE"]
long_expressions = [(x[0], x[4]) for x in academicList if x[3] == "LongExpress"]
longexpressList = [x[4] for x in academicList if x[3] == "LongExpress"]


def get_acadType(word):
    for x in academicList:
        if word == x[0]:
            return (x[0], x[1])


acad = [w[2] for w in academicList]

informBig = open("Dicts/pairs_auto_final.txt", "r").readlines()
informBig = [x.strip("\n").split("\t") for x in informBig]
informBig = [x[5] for x in informBig]
informList = open("Dicts/pairs_human_final.txt", "r").readlines()
informList = [x.strip("\n").split("\t") for x in informList]
longinformList = [x[1].strip() for x in informList]
formal = [x[6].strip() for x in informList]
inform = [x[5].strip() for x in informList]
brook = open("Dicts/CTRWpairsfull.txt", "r").readlines()
brook = [x.strip("\n").split("/") for x in brook]
brook = [x[0] for x in brook]
inform = list(set(inform + brook))  # +informBig))
allforms = list(set(inform + brook + formal + acad))


def is_informal(word):
    for x in inform:
        if x == word:
            return True


def is_inallforms(word):
    for x in allforms:
        if x == word:
            return True


to_add_list = [
    "blueprint",
    "rent",
    "budget",
    "problem",
    "computer",
    "beach",
    "car",
    "finance",
    "funding",
    "page",
    "wild",
    "disclaimer",
    "sample",
    "politics",
    "answer",
    "park",
    "plumber",
    "ashame",
    "meeting",
    "phone",
    "service",
    "identity",
    "family",
    "listen",
    "industry",
    "read",
]
acad = acad + formal + to_add_list


def is_acad(word):
    if word in acad:
        return True


ouraddition = [w[4].strip() for w in academicList if w[3] == "OurAddition"]
ouraddition = list(set(ouraddition))
# print("ouraddition",ouraddition)


def getAcads(word, pos):
    res = [x[2] for x in academicList if word in x[4] and pos[0:2] == x[1]]
    return res


def sentMatrix(sent):
    words = [w.text for w in snlp(sent)]
    deps = [w.dep_ for w in snlp(sent)]
    poses = [w.pos_ for w in snlp(sent)]
    tags = [w.tag_ for w in snlp(sent)]
    heads = [w.head for w in snlp(sent)]
    children = [w.children for w in snlp(sent)]
    all_list = [words, deps, poses, tags, heads, children]
    arr = np.array(all_list, dtype="str").view(np.chararray)
    # print(arr)
    return arr


def stanzaMatrix(sent):
    doc = nlp(sent)
    words = [word.text for sent in doc.sentences for word in sent.words]
    lemmas = [word.lemma for sent in doc.sentences for word in sent.words]
    xposes = [word.xpos for sent in doc.sentences for word in sent.words]
    uposes = [word.upos for sent in doc.sentences for word in sent.words]
    deps = [word.deprel for sent in doc.sentences for word in sent.words]
    heads = [
        sent.words[word.head - 1].text for sent in doc.sentences for word in sent.words
    ]
    all_list = [words, deps, uposes, xposes, heads, lemmas]
    arr = np.array(all_list, dtype="str").view(np.chararray)
    # print(arr)
    return arr


def mwe(sents):
    cases = ["advmod", "case", "compound:prt", "fixed", "nmod", "obl"]
    articles = [
        "through",
        "along",
        "onto",
        "about",
        "for",
        "aside",
        "into",
        "by",
        "up",
        "off",
        "over",
        "to",
        "on",
        "around",
        "without",
        "with",
        "under",
        "back",
        "out",
        "forward",
        "away",
        "at",
        "against",
        "apart",
        "across",
        "together",
        "ahead",
        "in",
        "after",
        "down",
    ]
    mwes = []
    for sent in sents:
        a = sentMatrix(sent)
        arr = stanzaMatrix(sent)
        b = arr[1].tolist()
        words = arr[0].tolist()
        poses = arr[3].tolist()
        heads = a[4].tolist()
        lemmas = arr[5].tolist()
        c = zip(arr[4], words, b)
        for case in cases:
            if case in b and words[b.index(case)] in articles:
                target = lemmas[b.index(case)]
                head = heads[b.index(case)]
                headIndex = words.index(head)
                headWord = arr[5][headIndex]
                mainword = words[headIndex]
                mainmwe = "{} {}".format(mainword, target)
                if poses[headIndex] != "NNP":
                    mwes.append(
                        (
                            headIndex,
                            headWord,
                            poses[headIndex],
                            b.index(case),
                            target,
                            mainmwe,
                        )
                    )
    # print("MWES:\n=================\n",mwes,"\n==========================\n")
    return mwes


def longExpress(sents):
    out_words = []
    out_keywords = []
    out_sent = []
    keywords = []
    ss = ""
    words = ""
    for n in long_expressions:
        mysent = ""
        if n[1] in sents:
            keywords.append(n[0])
            words = n[1].replace(" ", "_")
            mysent = sents.replace(n[1], words)
            sents = mysent
            out_words.append(words)
            out_keywords.append(keywords)
    out_sent.append(sents)
    result = []
    if out_words:
        a = stanzaMatrix(out_sent[0])
        words = a[0].tolist()
        poses = a[3].tolist()
        for x in words:
            if "_" in x:
                loc = words.index(x)
                result.append((loc, x, poses[loc], x, x, "long"))
    if result:
        # print("loooong,",out_sent[0],result,out_sent)
        return out_sent[0], result


def longInformCheck(sent):
    result = []
    sent = sent[0].lower() + sent[1:]
    res = [x for x in human_mwes if x in sent.lower()]
    ss = ""
    if res:
        mysent = ""
        for r in res:
            word_length = len(nltk.word_tokenize(r))
            # print(r,word_length)
            try:
                if word_length > 1 and r not in longexpressList:
                    words_list = [x[6].strip() for x in informList if r == x[1].strip()]
                    words = r.replace(" ", "_")
                    if words not in mwe_list:
                        mysent = sent.replace(r, words)
                        # print(r, mysent)
                        a = sentMatrix(mysent)
                        new_words = a[0].tolist()
                        # poses = a[3].tolist()
                        loc = new_words.index(words)
                        # print(words, loc)
                        sent = mysent
                        result.append(
                            (
                                loc,
                                words,
                                "NNP",
                                words.replace("_", " "),
                                words,
                                "longinform",
                            )
                        )
            except:
                mysent = ""
                pass
    if result:
        result = list(set(result))
    return sent, result


def inflecting(word, pos):
    if len(word.split(" ")) > 1:
        return word
    else:
        if pos.startswith("V"):
            part = "verb"
            mypos = "v"
        elif pos.startswith("N"):
            part = "noun"
            mypos = "n"
        else:
            return word
        cmd = ["node", "inflect.js", part, word, pos]
        output = subprocess.Popen(cmd, stdout=subprocess.PIPE).communicate()[0]
        infl = str(output).split("|")

        if pos == "NN" or pos == "JJ":
            return infl[2]
        elif pos == "NNS":
            return infl[1]
        else:
            if infl:
                return infl[1]


def acadFormat(mytext, out):
    for x in out:
        keyindex = x[0][0]
        myword = x[0][3]
        mylist = x[1]
        targetWord = x[0][3]
        keysList = mylist + ["-------"] + [targetWord.replace("_", " ")]
        keytype = x[0][5]
        # print(x, keysList)
        if mylist:
            select = []
            for w in keysList:
                pprt = "<option>{}</option>".format(w)
                select.append(pprt)
            mytext[
                keyindex
            ] = "<span style='color:red'><del>{}</del></span> <select>{}</select>".format(
                myword, "".join(select)
            )
        else:
            mytext[keyindex] = "<span style='color:green'>{}</span>".format(
                mytext[keyindex]
            )
    return " ".join(mytext)


def generator(text, postedList, userdegree):
    result = paragraph(text, postedList, int(userdegree)).formatting()
    finaltext = result[0]
    return finaltext, "ok"


class vocab:
    def __init__(self, text, userlist, degree):
        self.text = text
        self.text = self.text.replace("_", " ")
        self.userlist = userlist
        self.degree = degree
        # print("started here")
        self.proc()
        self.bert()
        self.results.clear()
        self.infelct()
        self.formatting()

    def infelct(self):
        # print("INFELCT",self.bertresults)
        if self.bertresults:
            for x in self.bertresults:
                if x[1][0] == x[0][3]:
                    pass
                else:
                    res = []
                    words = x[1]
                    myword = x[0][1]
                    pos = x[0][2]
                    for word in words:
                        # infl = inflecting(word,pos)
                        if "_" not in myword:
                            infl = getInflection(word, tag=pos)
                            if infl:
                                res.append(infl[0])
                            else:
                                res.append(word)
                        else:
                            res.append(word)
                    self.results.append((x[0], res))

    def proc(self):
        self.pre_proc = []
        self.mytext = self.text
        longexpress = longExpress(self.text)
        if longexpress:
            self.mytext = longexpress[0]
            for long in longexpress[1]:
                self.pre_proc.append(long)

        b = stanzaMatrix(self.mytext)
        self.sent = b[0].tolist()
        self.words = b[5].tolist()
        self.poses = b[3].tolist()
        targets = [
            (x[0], x[1], self.poses[x[0]], self.sent[x[0]])
            for x in enumerate(self.words)
            if is_inallforms(x[1])
        ]
        targets = [x for x in targets if (x[3] not in stops and x[2] != "IN")]
        # print("targets",targets)
        additions = [
            (x[0], x[1])
            for x in enumerate(self.sent)
            if x[1] in ouraddition and not is_acad(x[1])
        ]
        self.abbrevs = [
            (x[0], x[1], self.words[x[0]])
            for x in enumerate(self.sent)
            if "’" in x[1] or "'" in x[1]
        ]

        mwes = [x for x in mwe([self.text]) if "{}_{}".format(x[1], x[4]) in inform]
        self.removals = []
        self.mw_words = []
        self.add_words = []
        if mwes:
            for i in mwes:
                mw = "{}_{}".format(i[1], i[4])
                for_proc = (i[0], i[1], i[2], i[5], mw, "meew")
                # filtered_targets = [x for x in targets if x != for_proc]
                # keywords = list(set([n[2] for n in academicList if mw in n[4]]))
                # if keywords:
                self.pre_proc.append(for_proc)
                self.mw_words.append(i[0])
                to_remove = (i[4], i[3])
                self.removals.append(to_remove)
        if additions:
            for ad in additions:
                res = [x for x in academicList if ad[1] == x[4]]
                adindex = ad[0]
                adword = ad[1]
                if res:
                    pos = res[0][1]
                else:
                    pos == "XX"

                forproc = (adindex, adword, pos, adword, adword, "add")
                self.add_words.append(adindex)
                # keywords = list(set([n[2] for n in academicList if adword in n[4]]))
                self.pre_proc.append(forproc)
        self.acads = []
        nonacad = [x for x in targets if not is_acad(x[1])]
        if targets:
            for x in targets:
                mainword = x[3]
                # aa = list(set([n[2] for n in academicList if x[1] in n[4] and x[2][0:2] == n[1]]))
                for_proc = list(x) + [mainword] + ["nonacad"]
                self.pre_proc.append(tuple(for_proc))
        # print("pre_proc",pre_proc)
        self.pre_proc = list(set(self.pre_proc))
        # print("pre_proc",self.pre_proc)
        self.results = []
        for p in self.pre_proc:
            if p[5] == "meew":
                # print("MEEW",p)
                keywords = list(set([n[2] for n in academicList if p[4] == n[4]]))
                # print("MEEW Keys",keywords)
            elif p[5] == "add":
                keywords = list(set([n[2] for n in academicList if p[4] == n[4]]))
            elif p[5] == "long":
                keywords = [
                    w[0]
                    for w in academicList
                    if w[3] == "LongExpress" and w[4] == p[1].replace("_", " ")
                ]
            else:
                keywords = list(
                    set(
                        [
                            n[2]
                            for n in academicList
                            if (p[1] in n[4] and p[2][0:2] == n[1])
                        ]
                    )
                )
                # print("ACAD:", p, keywords[0:10])
            self.results.append((p, keywords))

        self.results = [x for x in self.results if x[0][3] not in self.userlist]

    def bert(self):
        # print("BERT START",self.results)
        self.bertresults = []
        for index in self.results:
            # print("BERT=====\n",sent,index[0],index[1][0:10],"\n=======")
            res = []
            if index[0][5] not in ["add", "long", "meew"]:
                mykeys = index[1]
                keyindex = index[0][0]
                mainword = index[0][3]
                targetword = index[0][1]
                s = self.sent
                s[keyindex] = "[MASK]"
                sentence = " ".join(s)
                input_ids = torch.tensor(
                    langmodel.bert_tokenizer.encode(sentence)
                ).unsqueeze(0)
                outputs = langmodel.bert_model(input_ids, masked_lm_labels=input_ids)
                pre = outputs[1].topk(23000)
                words = pre[1]
                best_words = words[0][keyindex]
                scores = pre[0]
                best_scores = scores[0][keyindex]
                predictions = [
                    langmodel.bert_tokenizer.convert_ids_to_tokens(x.tolist())
                    for x in best_words
                ]
                output1 = list(zip(predictions, [x.item() for x in best_scores]))
                output = sorted(output1, key=lambda tup: tup[1], reverse=True)
                ranked_words = [x[0] for x in output]
                out1 = ranked_words[0 : self.degree]
                mybertout = [x for x in out1 if x in mykeys]
                # print("OUT",mybertout[0:10],mainword)
                if mybertout:
                    self.bertresults.append((index[0], mybertout[0:5]))
                else:
                    s[keyindex] = mainword
                if "[MASK]" in s:
                    s[keyindex] = mainword
            else:
                # print("HERE",index[0][2], index[0])
                self.bertresults.append((index[0], index[1][0:5]))

    def formatting(self):
        res = [x for x in self.results if x]
        myres = res + self.acads
        mytext = self.sent
        # print("OUTTT",self.results,"\n",self.acads)
        abrlength = len(self.abbrevs)
        allwords = [x[0][1] for x in self.results if x]
        allacads = [x for x in allwords if not is_informal(x)]
        allinforms = [x for x in allwords if is_informal(x)]
        # print(allwords, allacads, allinforms, abrlength)
        textlength = len(self.sent)
        convertlength = len(self.results)
        fullconversion = len(allwords) + abrlength
        acadlength = len(allacads)
        nonacadlength = len(allinforms) + abrlength
        acadperc = round((acadlength / textlength) * 100, 1)
        nonacadperc = round((nonacadlength / textlength) * 100, 1)
        totalchange = round(((nonacadlength + abrlength) / textlength) * 100, 1)
        stats = {
            "textlength": textlength,
            "convertlength": convertlength,
            "abrlength": abrlength,
            "fullconversion": fullconversion,
            "acadlength": acadlength,
            "nonacadlength": nonacadlength,
            "acadperc": acadperc,
            "nonacadperc": nonacadperc,
            "totalchange": totalchange,
        }

        for x in myres:
            # try:
            keyindex = x[0][0]
            myword = x[0][3]
            mylist = x[1]
            targetWord = x[0][3]
            keysList = [targetWord.replace("_", " ")] + mylist
            keytype = x[0][5]
            # print(x, keysList)
            if is_informal(x[0][1]):
                mycolor = "red"
            else:
                mycolor = "green"
            if mylist:
                if keytype != "Acad":
                    select = []
                    for w in keysList:
                        pprt = '<li role="presentation"><a href="#" role="menuitem" tabindex="-1">{}</a></li>'.format(
                            w
                        )
                        select.append(pprt)
                    mytext[
                        keyindex
                    ] = "<li class='dropdown' style='display:inline-block'><span class='dropdown-toggle' data-toggle='dropdown' style='text-decoration:underline;color:{}'>{}</span><ul class='dropdown-menu' role='menu' aria-labelledby='menu1'>{}</ul></li>".format(
                        mycolor, myword, "".join(select)
                    )
                else:
                    # print("HEREEE",x)
                    mytext[keyindex] = "<span style='color:green'>{}</span>".format(
                        mytext[keyindex]
                    )
        # except:
        # pass
        for r in self.removals:
            mytext[r[1]] = "<span style='color:red'><del>{}</del></span>".format(r[0])
        if mytext[0] == "Also":
            mytext[
                0
            ] = "<li class='dropdown' style='display:inline-block'><span class='dropdown-toggle' data-toggle='dropdown' style='text-decoration:underline;color:red'>Also</span><ul class='dropdown-menu' role='menu' aria-labelledby='menu1'> <li role='presentation'><a href='#' role='menuitem' tabindex='-1'>Furthermore</a></li><li role='presentation'><a href='#' role='menuitem' tabindex='-1'>Moreover</a></li></ul></li>"
        elif mytext[0] == "So":
            mytext[
                0
            ] = "<span style='color:red'><del>Also</del></span> <select><option>Therefore</option></select>"
            mytext[
                0
            ] = "<li class='dropdown' style='display:inline-block'><span class='dropdown-toggle' data-toggle='dropdown' style='text-decoration:underline;color:red'>So</span><ul class='dropdown-menu' role='menu' aria-labelledby='menu1'> <li role='presentation'><a href='#' role='menuitem' tabindex='-1'>Therefore</a></li></ul></li>"
        tobes = {
            "'re": "are",
            "'s": "is",
            "'m": "am",
            "'ve": "have",
            "n't": "not",
            "'ll": "will",
            "'d": "would",
            "’re": "are",
            "’s": "is",
            "’m": "am",
            "’ve": "have",
            "n’t": "not",
            "’ll": "will",
            "’d": "would",
        }
        for ab in self.abbrevs:
            if ab[2] == "be":
                mytext[
                    ab[0]
                ] = "<span style='color:red'><del>{}</del> {} </span>".format(
                    ab[1], tobes[ab[1]]
                )
            else:
                mytext[
                    ab[0]
                ] = "<span style='color:red'><del>{}</del> {} </span>".format(
                    ab[1], ab[2]
                )
        finaltext = " ".join(mytext)
        finaltext = finaltext.replace(
            "ca <span style='color:red'>n't<del> not", "cannot"
        )
        # print(finaltext,stats)
        return finaltext, stats  # ,out,mytext


class paragraph:
    def __init__(self, text, userlist, degree):
        self.text = text
        self.text = self.text.replace("_", " ")
        self.text = self.text.replace(",", " ,")
        self.text = self.text.replace(".", " .")
        self.userlist = userlist
        self.degree = degree
        # print("start here")
        self.proc()
        self.bert()
        self.results.clear()
        self.infelct()
        self.formatting()

    def infelct(self):
        # print("INFELCT",self.bertresults)
        if self.bertresults:
            for x in self.bertresults:
                if x[1][0] == x[0][3]:
                    pass
                else:
                    res = []
                    words = x[1]
                    myword = x[0][1]
                    pos = x[0][2]
                    for word in words:
                        # infl = inflecting(word,pos)
                        if "_" not in myword:
                            infl = getInflection(word, tag=pos)
                            if infl:
                                res.append(infl[0])
                            else:
                                res.append(word)
                        else:
                            res.append(word)
                    self.results.append((x[0], res))

    def proc(self):
        self.pre_proc = []
        self.mytext = self.text
        longinform = longInformCheck(self.mytext)
        if longinform:
            self.mytext = longinform[0]
            for longi in longinform[1]:
                self.pre_proc.append(longi)
        longexpress = longExpress(self.text)
        if longexpress:
            self.mytext = longexpress[0]
            for long in longexpress[1]:
                self.pre_proc.append(long)
        # b = stanzaMatrix(self.mytext)
        b = sentMatrix(self.mytext)
        self.sent = b[0].tolist()
        self.words = b[5].tolist()
        self.poses = b[3].tolist()
        targets = [
            (x[0], x[1], self.poses[x[0]], self.sent[x[0]])
            for x in enumerate(self.words)
            if "_" not in x[1] and is_informal(x[1])
        ]
        additions = [
            (x[0], x[1])
            for x in enumerate(self.sent)
            if x[1] in ouraddition and not is_acad(x[1])
        ]
        self.abbrevs = [
            (x[0], x[1], self.words[x[0]])
            for x in enumerate(self.sent)
            if "’" in x[1] or "'" in x[1]
        ]
        # print("520 MWES sent post",self.text)
        mwes = [x for x in mwe([self.text]) if "{}_{}".format(x[1], x[4]) in inform]
        # print("mwes 483",mwes)
        self.removals = []
        self.mw_words = []
        self.add_words = []
        if mwes:
            for i in mwes:
                mw = "{}_{}".format(i[1], i[4])
                for_proc = (i[0], i[1], i[2], i[5], mw, "meew")
                # filtered_targets = [x for x in targets if x != for_proc]
                # keywords = list(set([n[2] for n in academicList if mw in n[4]]))
                # if keywords:
                self.pre_proc.append(for_proc)
                self.mw_words.append(i[0])
                to_remove = (i[4], i[3])
                self.removals.append(to_remove)
        if additions:
            for ad in additions:
                res = [x for x in academicList if ad[1] == x[4]]
                adindex = ad[0]
                adword = ad[1]
                if res:
                    pos = res[0][1]
                else:
                    pos == "XX"

                forproc = (adindex, adword, pos, adword, adword, "add")
                self.add_words.append(adindex)
                # keywords = list(set([n[2] for n in academicList if adword in n[4]]))
                self.pre_proc.append(forproc)
        self.acads = [
            ((x[0], x[1], x[2], x[3], x[1], "Acad"), getAcads(x[1], x[2]))
            for x in targets
            if is_acad(x[1])
        ]
        nonacad = [x for x in targets if not is_acad(x[1])]
        if nonacad:
            for x in nonacad:
                mainword = x[3]
                # aa = list(set([n[2] for n in academicList if x[1] in n[4] and x[2][0:2] == n[1]]))
                for_proc = list(x) + [mainword] + ["nonacad"]
                self.pre_proc.append(tuple(for_proc))
        # print("pre_proc",pre_proc)
        self.pre_proc = list(set(self.pre_proc))
        # print("pre_proc 519",self.pre_proc)
        self.results = []
        for p in self.pre_proc:
            # print("552", p, list(p[4]))
            if p[5] == "meew":
                # print("MEEW",p)
                keywords = list(set([n[2] for n in academicList if p[4] == n[4]]))
                # print("MEEW Keys",keywords)
            elif p[5] == "add":
                keywords1 = list(set([n[2] for n in academicList if p[4] == n[4]]))
                keywords2 = list(
                    set(
                        [
                            n[2]
                            for n in academicList
                            if len(list(p[4])) > 2
                            and p[4] in n[4]
                            and p[2][0:2] == n[1]
                        ]
                    )
                )
                keywords = list(set(keywords1 + keywords2))
                # print("Addition Keywords",keywords)
            elif p[5] == "long":
                keywords = [
                    w[0]
                    for w in academicList
                    if w[3] == "LongExpress" and w[4] == p[1].replace("_", " ")
                ]
            elif p[5] == "longinform":
                keywords1 = [w[2] for w in informList if w[1] == p[1].replace("_", " ")]
                keywords2 = [
                    w[0] for w in academicList if p[1].replace("_", " ") in w[4]
                ]
                keywords = list(set(keywords1 + keywords2))
            else:
                keywords = list(
                    set(
                        [
                            n[2]
                            for n in academicList
                            if p[1] in n[4] and p[2][0:2] == n[1]
                        ]
                    )
                )
            self.results.append((p, keywords))

        self.results = [x for x in self.results if x[0][3] not in self.userlist]
        # print("579", self.results)

    def bert(self):
        # print("BERT START",self.results)
        self.bertresults = []
        for index in self.results:
            # print("BERT=====\n",sent,index[0],index[1][0:10],"\n=======")
            res = []
            if index[0][5] in ["nonacad", "Acad", "add", "long"]:
                mykeys = index[1]
                keyindex = index[0][0]
                mainword = index[0][3]
                targetword = index[0][1]
                s = self.sent
                s[keyindex] = "[MASK]"
                sentence = " ".join(s)
                # print("BERT sentence",sentence,mykeys,keyindex)
                input_ids = torch.tensor(
                    langmodel.bert_tokenizer.encode(sentence)
                ).unsqueeze(0)
                outputs = langmodel.bert_model(input_ids, masked_lm_labels=input_ids)
                pre = outputs[1].topk(23000)
                words = pre[1]
                best_words = words[0][keyindex]
                scores = pre[0]
                best_scores = scores[0][keyindex]
                predictions = [
                    langmodel.bert_tokenizer.convert_ids_to_tokens(x.tolist())
                    for x in best_words
                ]
                output1 = list(zip(predictions, [x.item() for x in best_scores]))
                output = sorted(output1, key=lambda tup: tup[1], reverse=True)
                ranked_words = [x[0] for x in output]
                # print("BERT UP",ranked_words)
                out1 = ranked_words[0 : self.degree]
                mybertout = [x for x in out1 if x in mykeys]
                # print("OUT",mybertout,mainword)
                if mybertout:
                    self.bertresults.append((index[0], mybertout[0:5]))
                else:
                    if index[0][5] in ["add", "long"]:
                        sent_scores = []
                        for k in mykeys:
                            s[keyindex] = k
                            sent = " ".join(s)
                            bert_score = langmodel.bert_sent_score(sent)
                            finalscore = bert_score[1]
                            sent_scores.append((k, finalscore))
                        # print(sent_scores)
                        output = sorted(
                            sent_scores, key=lambda tup: tup[1], reverse=True
                        )
                        ranked_words = [x[0] for x in output]
                        # print("DOWN BERT",ranked_words)
                        self.bertresults.append((index[0], ranked_words[0:5]))
                    else:
                        s[keyindex] = mainword
            elif index[0][5] in ["meew", "longinform"]:
                # print("HERE",index[0][2], index[0])
                self.bertresults.append((index[0], index[1][0:5]))

    def formatting(self):
        res = [x for x in self.results if x]
        myres = res + self.acads
        mytext = self.sent
        # print("OUTTT",len(self.acads),len(self.results),len(self.abbrevs))
        textlength = len(self.sent)
        convertlength = len(self.results)
        abrlength = len(self.abbrevs)
        fullconversion = len(self.results) + len(self.abbrevs)
        acadlength = len(self.acads)
        nonacadlength = len(self.results) + len(self.abbrevs)
        acadperc = round((acadlength / textlength) * 100, 1)
        nonacadperc = round((nonacadlength / textlength) * 100, 1)
        totalchange = round(((nonacadlength) / textlength) * 100, 1)
        stats = {
            "textlength": textlength,
            "convertlength": convertlength,
            "abrlength": abrlength,
            "fullconversion": fullconversion,
            "acadlength": acadlength,
            "nonacadlength": nonacadlength,
            "acadperc": acadperc,
            "nonacadperc": nonacadperc,
            "totalchange": totalchange,
        }

        for x in myres:
            # try:
            keyindex = x[0][0]
            myword = x[0][3]
            mylist = x[1]
            targetWord = x[0][3]
            keysList = mylist + ["-------"] + [targetWord.replace("_", " ")]
            keytype = x[0][5]
            # print(x, keysList)
            if mylist:
                if keytype != "Acad":
                    select = []
                    for w in keysList:
                        if keyindex == 0:
                            w = w[0].upper() + w[1:]
                        pprt = "<option>{}</option>".format(w)
                        select.append(pprt)
                    mytext[
                        keyindex
                    ] = "<span style='color:red'><del>{}</del></span> <select>{}</select>".format(
                        myword, "".join(select)
                    )
                else:
                    mytextres = mytext[keyindex]
                    if keyindex == 0:
                        mytextres = mytext[keyindex]
                        mytextres = mytextres[0].upper() + mytextres[1:]
                    # print("HEREEE",x)
                    mytext[keyindex] = "<span style='color:green'>{}</span>".format(
                        mytextres
                    )
        # except:
        # pass
        for r in self.removals:
            mytext[r[1]] = "<span style='color:red'><del>{}</del></span>".format(r[0])
        if mytext[0] == "Also":
            mytext[
                0
            ] = "<span style='color:red'><del>Also</del></span> <select><option>Furthermore</option><option>Moreover</option></select>"
        elif mytext[0] == "So":
            mytext[
                0
            ] = "<span style='color:red'><del>Also</del></span> <select><option>Therefore</option></select>"
        tobes = {
            "'re": "are",
            "'s": "is",
            "'m": "am",
            "'ve": "have",
            "n't": "not",
            "'ll": "will",
            "'d": "would",
            "’re": "are",
            "’s": "is",
            "’m": "am",
            "’ve": "have",
            "n’t": "not",
            "’ll": "will",
            "’d": "would",
        }
        for ab in self.abbrevs:
            if ab[2] == "be":
                mytext[
                    ab[0]
                ] = "<span style='color:red'><del>{}</del> {} </span>".format(
                    ab[1], tobes[ab[1]]
                )
            else:
                mytext[
                    ab[0]
                ] = "<span style='color:red'><del>{}</del> {} </span>".format(
                    ab[1], tobes[ab[1]]
                )
        finaltext = " ".join(mytext)
        finaltext = finaltext.replace(
            "ca <span style='color:red'>n't<del> not", "cannot"
        )
        finaltext = finaltext.replace(
            "ca<span style='color:red'>n't<del> not", "cannot"
        )
        finaltext = finaltext[0].upper() + finaltext[1:]
        # print(finaltext,stats)
        return finaltext, stats  # ,out,mytext


def free_inflecting(word, mypos):
    posabv = mypos.lower()[0]
    if posabv == "j":
        posabv = "a"
    elif posabv not in ["j", "n", "v"]:
        posabv = "v"
    else:
        posabv = "v"
    word = lemmatizer.lemmatize(word, pos=posabv)
    res = []
    infl = getInflection(word, tag=mypos)
    if infl:
        res.append(infl[0])
    else:
        res.append(word)
    return res[0]


class freePhrase:
    def __init__(self, text, userlist, degree):
        self.text = text
        self.text = self.text.replace("_", " ")
        self.userlist = userlist
        self.degree = degree
        self.proc()
        self.formatting()

    def proc(self):
        marked_text = self.text
        arr = sentMatrix(self.text)
        arr2 = stanzaMatrix(self.text)
        self.sent = arr[0].tolist()
        self.words = arr2[5].tolist()
        self.poses = arr[3].tolist()
        tokenized_text = langmodel.bert_tokenizer3.tokenize(
            "[CLS] " + self.text + " [SEP]"
        )
        # self.sent = tokenized_text
        segments_ids = [1] * len(tokenized_text)
        indexed_tokens = langmodel.bert_tokenizer3.convert_tokens_to_ids(tokenized_text)
        tokens_tensor = torch.tensor([indexed_tokens])
        segments_tensors = torch.tensor([segments_ids])
        outputs = langmodel.bert_model3(tokens_tensor, segments_tensors)
        pre = outputs[0].topk(2000)
        words = pre[1]
        scores = pre[0]
        self.results = []
        for i, token_str in enumerate(self.sent):
            # print(i, token_str)
            a = sentMatrix(token_str)
            if (
                a[2][0] in ["NOUN", "VERB", "ADJ", "ADP"]
                and a[3][0] != "NNP"
                and token_str not in stops
                and len(token_str) > 2
            ):
                best_words = words[0][i + 1]
                best_scores = scores[0][i + 1]
                predictions = [
                    langmodel.bert_tokenizer3.convert_ids_to_tokens(x.tolist())
                    for x in best_words
                ]
                res = list(zip(predictions, [x.item() for x in best_scores]))
                res = [
                    x[0]
                    for x in res
                    if ("#" not in x[0] and len(x[0]) > 2 and x[0] != "UNK")
                ]
                myres = ", ".join(res)
                myres = sentMatrix(myres)
                b = list(zip(myres[0], myres[2], myres[3]))
                # print("HEREEEE",token_str, myres,b)
                # out = [free_inflecting(x[0],x[2]) for x in b if x[1] == a[2][0]]
                out = [x[0] for x in b if (x[1] == a[2][0] and x[2] == a[3][0])]
                keytype = []
                if not is_informal(token_str):
                    keytype = "Acad"
                else:
                    keytype = "nonacad"
                self.results.append((i, token_str, keytype, out[0:20]))
            else:
                pass

    def formatting(self):
        self.abbrevs = []
        self.removals = []
        myres = [x for x in self.results if x]
        mytext = self.sent
        allwords = [x[1] for x in self.results if x]
        allacads = [x for x in allwords if not is_informal(x)]
        allinforms = [x for x in allwords if is_informal(x)]
        # print(myres, allwords, allacads, allinforms)
        textlength = len(self.sent)
        convertlength = len(self.results)
        fullconversion = len(allwords)
        acadlength = len(allacads)
        nonacadlength = len(allinforms)
        acadperc = round((acadlength / textlength) * 100, 1)
        nonacadperc = round((nonacadlength / textlength) * 100, 1)
        totalchange = round((nonacadlength / textlength) * 100, 1)
        stats = {
            "textlength": textlength,
            "convertlength": convertlength,
            "abrlength": 0,
            "fullconversion": fullconversion,
            "acadlength": acadlength,
            "nonacadlength": nonacadlength,
            "acadperc": acadperc,
            "nonacadperc": nonacadperc,
            "totalchange": totalchange,
        }

        for x in myres:
            # try:
            keyindex = x[0]
            myword = x[1]
            targetWord = x[1]
            keytype = x[2]
            mylist = x[3]
            keysList = [targetWord.replace("_", " ")] + mylist
            # print(x, keysList)
            if is_informal(x[1]):
                mycolor = "red"
            else:
                mycolor = "green"
            if mylist:
                # print("HEREEE",x,myres)
                select = []
                for w in keysList:
                    pprt = '<li role="presentation"><a href="#" role="menuitem" tabindex="-1">{}</a></li>'.format(
                        w
                    )
                    select.append(pprt)
                mytext[
                    keyindex
                ] = "<li class='dropdown' style='display:inline-block'><span class='dropdown-toggle' data-toggle='dropdown' style='text-decoration:underline;color:{}'>{}</span><ul class='dropdown-menu' role='menu' aria-labelledby='menu1'>{}</ul></li>".format(
                    mycolor, myword, "".join(select)
                )
        # except:
        # pass
        finaltext = " ".join(mytext)
        finaltext = finaltext.replace(
            "ca <span style='color:red'>n't<del> not", "cannot"
        )
        # print(finaltext,stats)
        return finaltext, stats
