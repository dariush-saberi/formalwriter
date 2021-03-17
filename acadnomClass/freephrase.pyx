#!/usr/bin/env python
# coding: utf-8

import concurrent.futures
import subprocess
import traceback

import acadnomClass.acadz as acadz
import acadnomClass.langmodel as langmodel
import numpy as np


def processText(text):
    arr = acadz.stanzaMatrix(text)
    mywords = arr[0].tolist()
    mytags = arr[3].tolist()
    targets = []
    sent = mywords
    for x in enumerate(mywords):
        if (
            x[1] not in acadz.stops
            and x[1] not in "(),;."
            and mytags[x[0]] != "NNP"
            and x[1].lower() not in acadz.stops
            and not any(char.isdigit() for char in x[1])
        ):
            sent = mywords[:]
            sent[x[0]] = "[MASK]"
            targets.append((x[0], mytags[x[0]], x[1], sent))
    return mywords, targets


def bert(x):
    mypose = x[1][0]
    a = acadz.langmodel.bert_mask300(list(x[3]))
    words = " , ".join([w for w in a[0] if len(w) > 2])
    poses = acadz.stanzaMatrix(words)
    out = list(zip(poses[0], poses[3]))
    out = [w[0] for w in out if w[1].startswith(mypose) and "#" not in w[0]]
    return (x[0], x[1], x[2], out[0:10])


def formatting(text, words):
    for x in words:
        keyindex = x[0]
        myword = x[2]
        keysList = [myword] + x[3]
        mycolor = "green"
        select = []
        for w in keysList:
            pprt = '<li role="presentation"><a href="#" role="menuitem" tabindex="-1">{}</a></li>'.format(
                w
            )
            select.append(pprt)
        text[
            keyindex
        ] = "<li class='dropdown' style='display:inline-block'><span class='dropdown-toggle' data-toggle='dropdown' style='text-decoration:underline;color:{}'>{}</span><ul class='dropdown-menu' role='menu' aria-labelledby='menu1'>{}</ul></li>".format(
            mycolor, myword, "".join(select)
        )
    return " ".join(text)


def start(text):
    proc = processText(text)
    mywords = proc[0]
    targets = proc[1]
    bertresult = []
    for x in targets:
        b = bert(x)
        bertresult.append(b)
    res = formatting(mywords, bertresult)
    return res
