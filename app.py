# coding: utf-8
#!/usr/bin/python3
#!flask/bin/python3
import sys
import os.path
from flask import Flask, render_template, request, jsonify, session, g, Response
import nltk
import time 
import random
import string
from urllib.parse import quote
import urllib.request, json
from geolite2 import geolite2
from operator import itemgetter
import acadnomClass
import acadnomClass.nom as nom
import acadnomClass.acadz as academizer
import acadnomClass.freephrase as freephrase


app = Flask(__name__)

def get_ip_info(ip):
    try:
        geo = geolite2.reader()
        a = geo.get(ip)
        cont = a['continent']['names']['en']
        country = a['country']['names']['en']
        city = a['city']['names']['en']
        return ip,cont,country,city
    except:
        return ip,"unknown","unknown","unknown"

@app.route('/score', methods=['GET', 'POST'])
def score():
    sents = request.args.get('sents')
    model = request.args.get('model')
    sents = sents.split("|")
    scores = nom.caluse_score(sents,model)
    return jsonify(scores=scores)

@app.route('/workspace', methods=['GET', 'POST'])
def workspace():
    today = time.strftime('%Y-%m-%d %H:%M:%S')
    myip = request.remote_addr
    username = session.get("USERNAME")
    mycountry = get_ip_info(myip)
    user_info = "/".join(mycountry)
    if request.method == 'POST':
         text = request.form['sent']
         options = request.form['options']
         text = text.lstrip().rstrip().strip('\n').strip('<b>').strip()
         text = text.replace('"',"")
         text = text.replace('“','')
         text = text.replace('”','')
         text = text.replace('\n','')
         text = text.replace('<br>','')
         mylength = len(text.split())
         sents = nltk.sent_tokenize(text)
         return jsonify(sents=sents)
    else:
         return render_template('workspace.html', username=username)

@app.route('/nominals', methods=['GET', 'POST'])
def nominals():
    sent = request.args.get('text')
    results = nom.cline(sent)
    output = jsonify(results)
    return output    

@app.route('/nominal_maker', methods=['GET', 'POST'])
def nominal_maker():
    text = request.form['sent']
    sents = nltk.sent_tokenize(text)
    results = []
    for sent in sents:
        causative = nom.checkCause(sent)
        if causative:
            try:
                res = nom.cline(sent)
                res1 = u'{}'.format(res[0])
                res2 = u'{}'.format(res[1])
                res3 = u'{}'.format(res[2])
                res4 = u'{}'.format(res[3])
                posConversion = res[2]
            except:
                res1 = "notCause"
                res2 = "notCause"
                res3 = "notCause"
                res4 = "notCause"
                posConversion = "notCause"
        else:
            res = nom.cline(sent)
            res1 = u'{}'.format(res[0])
            res2 = u'{}'.format(res[1])
            res3 = u'{}'.format(res[2])
            res4 = u'{}'.format(res[3])
            posConversion = res[2]
        results.append({"Result":[res1,res2,res3,res4],"POS Conversion":posConversion, "Original":sent, "Rules":res[3],"Errors":res[4], "webColor":res[5],"moveTable":res[7]})

    output = jsonify(results)
    return output

@app.route('/phrase', methods=['GET', 'POST'])
def phrase():
    today = time.strftime('%Y-%m-%d %H:%M:%S')
    text = request.form['sent']
    userdegree = request.form['myrange']       
    postedList1 = request.form['wordlist']
    postedList = postedList1.split(",")
    text = text.lstrip().rstrip().strip('\n').strip('<b>').strip()
    text = text.replace('"',"")
    text = text.replace('“','')
    text = text.replace('”','')
    text = text.replace('\n','')
    text = text.replace('<br>','')
    mylength = len(text.split())
    myip = request.remote_addr
    username = session.get("USERNAME")
    mycountry = get_ip_info(myip)
    user_info = "/".join(mycountry)
    if not text.isspace() and mylength <= 400:
        #result = academizer.main(text,postedList,userdegree)
        #try:
        result = academizer.freePhrase(text,postedList,int(userdegree)).formatting()
        #except:
            #result = ['None','None']
    else:
        result = ['None','None']
    
    if result[0] == "None":
        textlength=mylength
        convertlength=0
        abrlength=0
        fullconversion=0
        acadlength=0
        nonacadlength=0
        acadperc=0
        nonacadperc=0
        totalchange=0
        result = "None"
        with open("serverlog","a") as f:
             f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),userdegree,postedList1,"Error"))
        f.close()
        return jsonify(result=result,text=text,username=username,textlength=textlength,convertlength=convertlength,abrlength=abrlength,fullconversion=fullconversion,acadlength=acadlength,nonacadlength=nonacadlength,acadperc=acadperc,nonacadperc=nonacadperc,totalchange=totalchange)
    else:
        stats = result[1]
        textlength = stats['textlength']
        convertlength = stats['convertlength']
        abrlength = stats['abrlength']
        fullconversion = stats['fullconversion']
        acadlength = stats['acadlength']
        nonacadlength = stats['nonacadlength']
        acadperc = stats['acadperc']
        nonacadperc = stats['nonacadperc']
        totalchange = stats['totalchange']
        with open("serverlog","a") as f:
             f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),userdegree,postedList1,result[0]))
        f.close()
        return jsonify(result=result[0],text=text,username=username,textlength=textlength,convertlength=convertlength,abrlength=abrlength,fullconversion=fullconversion,acadlength=acadlength,nonacadlength=nonacadlength,acadperc=acadperc,nonacadperc=nonacadperc,totalchange=totalchange)
    
@app.route('/phraseIt', methods=['GET', 'POST'])
def phraseIt():
    text = request.form['sent']
    text = text.lstrip().rstrip().strip('\n').strip('<b>').strip()
    text = text.replace('"',"")
    text = text.replace('“','')
    text = text.replace('”','')
    text = text.replace('\n','')
    text = text.replace('<br>','')
    res = freephrase.start(text)
    return jsonify(res=res)

@app.route('/report')
def reporting():
    mydate = request.args.get('date')
    data = open("serverlog","r").readlines()
    data = [x.strip().split("\t") for x in data]
    res = [x for x in data if mydate == x[0].split(" ")[0]]
    return render_template('report.html',res=res)

@app.route('/user')
def user():
    username = request.args.get('username')
    try:
         filepath = "userfiles/{}".format(username)
         data = open(filepath,"r").readlines()
         res = [x.strip().split("\t") for x in data]
         return jsonify(res=res)
    except:
         pass
         return jsonify(username=username)

@app.route('/vocabulary', methods=['GET'])
def vocabulary():
    username = request.args.get('u')
    if username:
         session["USERNAME"] = username
    else:
         session["USERNAME"] = myrandom()
    return render_template('indexvocab.html', username=session["USERNAME"])

@app.route('/vocab', methods=['GET', 'POST'])
def vocab():
    today = time.strftime('%Y-%m-%d %H:%M:%S')
    text = request.form['sent']
    userdegree = request.form['myrange']       
    postedList1 = request.form['wordlist']
    postedList = postedList1.split(",")
    text = text.lstrip().rstrip().strip('\n').strip('<b>').strip()
    text = text.replace('"',"")
    text = text.replace('“','')
    text = text.replace('”','')
    text = text.replace('\n','')
    text = text.replace('<br>','')
    mylength = len(text.split())
    myip = request.remote_addr
    username = session.get("USERNAME")
    mycountry = get_ip_info(myip)
    user_info = "/".join(mycountry)
    if not text.isspace() and mylength <= 400:
        #result = academizer.main(text,postedList,userdegree)
        try:
            result = academizer.vocab(text,postedList,int(userdegree)).formatting()
        except:
            result = ['None','None']
    else:
        result = ['None','None']
    
    if result[0] == "None":
        textlength=mylength
        convertlength=0
        abrlength=0
        fullconversion=0
        acadlength=0
        nonacadlength=0
        acadperc=0
        nonacadperc=0
        totalchange=0
        result = "None"
        with open("serverlog","a") as f:
             f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),userdegree,postedList1,"Error"))
        f.close()
        return jsonify(result=result,text=text,username=username,textlength=textlength,convertlength=convertlength,abrlength=abrlength,fullconversion=fullconversion,acadlength=acadlength,nonacadlength=nonacadlength,acadperc=acadperc,nonacadperc=nonacadperc,totalchange=totalchange)
    else:
        stats = result[1]
        textlength = stats['textlength']
        convertlength = stats['convertlength']
        abrlength = stats['abrlength']
        fullconversion = stats['fullconversion']
        acadlength = stats['acadlength']
        nonacadlength = stats['nonacadlength']
        acadperc = stats['acadperc']
        nonacadperc = stats['nonacadperc']
        totalchange = stats['totalchange']
        with open("serverlog","a") as f:
             f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),userdegree,postedList1,result[0]))
        f.close()
        return jsonify(result=result[0],text=text,username=username,textlength=textlength,convertlength=convertlength,abrlength=abrlength,fullconversion=fullconversion,acadlength=acadlength,nonacadlength=nonacadlength,acadperc=acadperc,nonacadperc=nonacadperc,totalchange=totalchange)


@app.route('/', methods=['GET'])
def index():
    username = request.args.get('u')
    if username:
         session["USERNAME"] = username
    else:
         session["USERNAME"] = myrandom()
    return render_template('index.html', username=session["USERNAME"])

@app.route('/generate', methods=['GET', 'POST'])
def generate():
    username = request.args.get('u')
    if username:
         session["USERNAME"] = username
    else:
         session["USERNAME"] = myrandom()
    return render_template('index_generate.html', username=session["USERNAME"])

@app.route('/generator', methods=['GET', 'POST'])
def generator():
    text = request.form['sent']
    userdegree = 500       
    postedList = request.form['genbut']
    text = text.lstrip().rstrip().strip('\n').strip('<b>').strip()
    text = text.replace('"',"")
    text = text.replace('“','')
    text = text.replace('”','')
    text = text.replace('\n','')
    text = text.replace('<br>','')
    today = time.strftime('%Y-%m-%d %H:%M:%S')
    myip = request.remote_addr
    username = session.get("USERNAME")
    mycountry = get_ip_info(myip)
    user_info = "/".join(mycountry)
    mylength = len(text.split())
    if mylength <= 305:
        result = academizer.generator(text,postedList,userdegree)
    else:
        result = ['None','None']
    with open("serverlog","a") as f:
        f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),"Generator",postedList,result[0]))
    f.close()
    return jsonify(result=result[0],comment=result[1],textlength=mylength)

@app.route('/nominalize', methods=['GET', 'POST'])
def nominalize():
    username = request.args.get('u')
    if username:
         session["USERNAME"] = username
    else:
         session["USERNAME"] = myrandom()
    return render_template('index_nom.html', username=session["USERNAME"])

@app.route('/nomit', methods=['GET', 'POST'])
def nomit():
    text = request.form['sent']
    sents = nltk.sent_tokenize(text)
    results = []
    for sent in sents:
        causative = nom.checkCause(sent)
        if causative:
            try:
                res = nom.cline(sent)
                print(res) 
                res1 = u'{}'.format(res[0])
                res2 = u'{}'.format(res[1])
                res3 = u'{}'.format(res[2])
                res4 = u'{}'.format(res[3])
                posConversion = res[2]
            except:
                res1 = "notCause"
                res2 = "notCause"
                res3 = "notCause"
                res4 = "notCause"
                posConversion = "notCause"
        else:
            res = "notCause"
            res1 = "notCause"
            res2 = "notCause"
            res3 = "notCause"
            res4 = "notCause"
            posConversion = "notCause"
        results.append({"Result":[res1,res2,res3,res4],"Original":sent, "Rules":res[3],"Errors":res[4], "webColor":res[5],"moveTable":res[7]})

    output = jsonify(results)
    return output

def myrandom():
    char_set = string.ascii_uppercase + string.digits
    return ''.join(random.sample(char_set*12, 12))

@app.route('/save', methods=['GET', 'POST'])
def save():
    today = time.strftime('%Y-%m-%d %H:%M:%S')
    cleaned = request.form['cleaned']
    sent = request.form['sent']
    proc = request.form['proc']
    user = request.form['user']   
    filepath = "userfiles/{}".format(user)
    out = "{}\t{}\t{}\t{}\t{}\n".format(today,user,sent,proc,cleaned)
    if os.path.isfile(filepath):
         available_data = [x for x in open(filepath,'r').readlines() if proc in x]
         if not available_data:
              with open(filepath,'a') as f:
                   f.write(out)
              f.close()
    else:
         with open(filepath,'w') as f:
              f.write(out)
         f.close()

    return jsonify(user=user)

@app.route('/academize', methods=['GET', 'POST'])
def academize():
    today = time.strftime('%Y-%m-%d %H:%M:%S')
    text = request.form['sent']
    userdegree = request.form['myrange']       
    postedList1 = request.form['wordlist']
    postedList = postedList1.split(",")
    text = text.lstrip().rstrip().strip('\n').strip('<b>').strip()
    text = text.replace('"',"")
    text = text.replace('“','')
    text = text.replace('”','')
    text = text.replace('\n','')
    text = text.replace('<br>','')
    mylength = len(text.split())
    myip = request.remote_addr
    username = session.get("USERNAME")
    mycountry = get_ip_info(myip)
    user_info = "/".join(mycountry)
    if not text.isspace() and mylength <= 400:
        #result = academizer.main(text,postedList,userdegree)
        try:
            result = academizer.paragraph(text,postedList,int(userdegree)).formatting()
        except IOError:
            #type, value, traceback = sys.exc_info()
            #print('Error opening %s: %s' % (value.filename, value.strerror))
            result = ['None','None']
            pass
    else:
        result = ['None','None']
    
    if result[0] == "None":
        textlength=mylength
        convertlength=0
        abrlength=0
        fullconversion=0
        acadlength=0
        nonacadlength=0
        acadperc=0
        nonacadperc=0
        totalchange=0
        result = "None"
        with open("serverlog","a") as f:
             f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),userdegree,postedList1,"Error"))
        f.close()
        return jsonify(result=result,text=text,username=username,textlength=textlength,convertlength=convertlength,abrlength=abrlength,fullconversion=fullconversion,acadlength=acadlength,nonacadlength=nonacadlength,acadperc=acadperc,nonacadperc=nonacadperc,totalchange=totalchange)
    else:
        stats = result[1]
        textlength = stats['textlength']
        convertlength = stats['convertlength']
        abrlength = stats['abrlength']
        fullconversion = stats['fullconversion']
        acadlength = stats['acadlength']
        nonacadlength = stats['nonacadlength']
        acadperc = stats['acadperc']
        nonacadperc = stats['nonacadperc']
        totalchange = stats['totalchange']
        with open("serverlog","a") as f:
             f.write("{}\t{}\t{}\t{}\t{}\t{}\t{}\n".format(today,user_info,username,text.strip("\t").strip("<br>").strip("\n"),userdegree,postedList1,result[0]))
        f.close()
        return jsonify(result=result[0],text=text,username=username,textlength=textlength,convertlength=convertlength,abrlength=abrlength,fullconversion=fullconversion,acadlength=acadlength,nonacadlength=nonacadlength,acadperc=acadperc,nonacadperc=nonacadperc,totalchange=totalchange)

if __name__ == '__main__':
     app.run(host='0.0.0.0',port=8010,debug=True)
