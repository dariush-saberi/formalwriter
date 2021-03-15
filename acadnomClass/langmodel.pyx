#!/usr/bin/env python
# coding: utf-8

import torch
from transformers import *
import numpy as np
from scipy.special import softmax
import math

with torch.no_grad():

    bert_tokenizer = BertTokenizer.from_pretrained('bert-large-cased')
    bert_model = BertForMaskedLM.from_pretrained('bert-large-cased')
    bert_tokenizer3 = BertTokenizer.from_pretrained('bert-base-cased')
    bert_model3 = BertForMaskedLM.from_pretrained('bert-base-cased')
    xlnet_tokenizer = XLNetTokenizer.from_pretrained('xlnet-base-cased')
    xlnet_model = XLNetLMHeadModel.from_pretrained('xlnet-base-cased')
    bert_model.eval()
    #xlnet_model.eval()

def bert_mask300(sent):
    tokens = ['[CLS]']+sent+['[SEP]']
    mask_index = tokens.index("[MASK]")
    indices = [i for i,val in enumerate(tokens) if val=="[MASK]"]
    results = []
    for index in indices:
        sentence = " ".join(tokens)
        input_ids = torch.tensor(bert_tokenizer.encode(sentence)).unsqueeze(0)
        outputs = bert_model(input_ids, masked_lm_labels=input_ids)
        pre = outputs[1].topk(100)
        words = pre[1]
        best_words = words[0][index]
        scores = pre[0]
        best_scores = scores[0][index]
        #best_scores = np.array(best_scores) / np.sum(best_scores)
        predictions = [bert_tokenizer.convert_ids_to_tokens(x.tolist()) for x in best_words]
        res = list(zip(predictions,[x.item() for x in best_scores]))
        results.append([x[0] for x in res])
    return results

def bert_mask_predict(sent):
    tokens = ['[CLS]']+sent.split()+['[SEP]']
    mask_index = tokens.index("[MASK]")
    indices = [i for i,val in enumerate(tokens) if val=="[MASK]"]
    results = []
    for index in indices:
        sentence = " ".join(tokens)
        input_ids = torch.tensor(bert_tokenizer.encode(sentence)).unsqueeze(0)
        outputs = bert_model(input_ids, masked_lm_labels=input_ids)
        pre = outputs[1].topk(50)
        words = pre[1]
        best_words = words[0][index]
        scores = pre[0]
        best_scores = scores[0][index]
        #best_scores = np.array(best_scores) / np.sum(best_scores)
        predictions = [bert_tokenizer.convert_ids_to_tokens(x.tolist()) for x in best_words]
        res = zip(predictions,[x.item() for x in best_scores])
        results.append([(x[0],round(x[1],2))[0:5] for x in res])
    return results

def bert_mask_predict_OLD2(sent):
    tokens = ['[CLS]']+sent.split()+['[SEP]']
    #print(tokens)
    mask_index = tokens.index("[MASK]")
    sentence = " ".join(tokens)
    input_ids = torch.tensor(bert_tokenizer.encode(sentence)).unsqueeze(0)
    outputs = bert_model(input_ids, masked_lm_labels=input_ids)
    pre = outputs[1].topk(50)
    words = pre[1]
    best_words = words[0][mask_index]
    scores = pre[0]
    best_scores = scores[0][mask_index]
    predictions = [bert_tokenizer.convert_ids_to_tokens(x.tolist()) for x in best_words]
    res = zip(predictions,[x.item() for x in best_scores])
    return [(x[0],round(x[1],2)) for x in res]
    
def bert_mask_predict_OLD(sent):
    sent = sent.split()
    target_index = sent.index('[MASK]')
    pre = " ".join(sent[:target_index])
    target = '[MASK]'
    post = " ".join(sent[target_index+1:])
    if 'mask' in target.lower():
        target=['[MASK]']
    else:
        target=bert_tokenizer.tokenize(target)
    tokens=['[CLS]']+bert_tokenizer.tokenize(pre)
    target_idx=len(tokens)
    #print(target_idx)
    tokens+=target+bert_tokenizer.tokenize(post)+['[SEP]']
    indexed_tokens=bert_tokenizer.convert_tokens_to_ids(tokens)

    segments_ids = [0] * len(tokens)
    # this is for the dummy first sentence. 
    segments_ids[0] = 0
    segments_ids[1] = 0
    tokens_tensor = torch.tensor([indexed_tokens])
    segments_tensors = torch.tensor([segments_ids])
    # Load pre-trained model (weights)

    # Predict all tokens
    predictions = bert_model(tokens_tensor, segments_tensors)
    predicted_index = torch.argmax(predictions[0][0, target_idx]).item()
    predicted_token = bert_tokenizer.convert_ids_to_tokens([predicted_index])
    #print(predicted_token)
    result = []
    #result.append(predicted_token)
    for i in range(50):
        predictions[0][0,target_idx,predicted_index] = -11100000
        predicted_index = torch.argmax(predictions[0][0, target_idx]).item()
        predicted_token = bert_tokenizer.convert_ids_to_tokens([predicted_index])
        res = predicted_token[0].replace('▁','')
        #print(res)
        result.append(res)
        
    return result



def xlnet_sent_score_OLD3(text): #new code based on xlnet working code in my drive
    PADDING_TEXT = """In 1991, the remains of Russian Tsar Nicholas II and his family
  (except for Alexei and Maria) are discovered. The voice of Nicholas's young son, Tsarevich Alexei Nikolaevich, narrates the
  remainder of the story. Although his father initially slaps him for making such an accusation, Rasputin watches as the
  man is chased outside and beaten. <eod> """
    tokenize_input = xlnet_tokenizer.tokenize(PADDING_TEXT+text)
    tokenize_text = xlnet_tokenizer.tokenize(text)
    sum_lp = 0.0
    for max_word_id in range((len(tokenize_input)-len(tokenize_text)), (len(tokenize_input))):
        sent = tokenize_input[:]
        input_ids = torch.tensor([xlnet_tokenizer.convert_tokens_to_ids(sent)])
        with torch.no_grad():
            outputs = xlnet_model(input_ids)
            next_token_logits = outputs[0] 
            #print(max_word_id,tokenize_input[max_word_id],outputs[0].shape)
        word_id = xlnet_tokenizer.convert_tokens_to_ids([tokenize_input[max_word_id]])[0]
        #print(word_id)
        predicted_prob = softmax(np.array(next_token_logits[0][-1]))
        #lp = np.log(predicted_prob[word_id])
        lp = predicted_prob[word_id]
        sum_lp += lp
    return text,sum_lp

def xlnet_sent_score(sent):
    text = "[CLS] "+sent[0].upper()+sent[1:]+" [SEP] "
    tokenize_input = xlnet_tokenizer.tokenize(text)
    tensor_input = torch.tensor([xlnet_tokenizer.convert_tokens_to_ids(tokenize_input)])
    predictions=xlnet_model(tensor_input)
    loss_fct = torch.nn.CrossEntropyLoss()
    loss = loss_fct(predictions[0][0].squeeze(),tensor_input.squeeze()).data 
    return sent,math.exp(loss)

def bert_sent_score(sent):
    text = "[CLS] "+sent[0].upper()+sent[1:]+" [SEP] "
    tokenize_input = bert_tokenizer.tokenize(text)
    tensor_input = torch.tensor([bert_tokenizer.convert_tokens_to_ids(tokenize_input)])
    predictions=bert_model(tensor_input)
    loss_fct = torch.nn.CrossEntropyLoss()
    loss = loss_fct(predictions[0][0].squeeze(),tensor_input.squeeze()).data 
    return sent,math.exp(loss)
   
def bert_sent_score_OLD3(text): #new code based on xlnet working code in my drive
    text = "[CLS] "+text[0].upper()+text[1:]+" [SEP] "
    tokenize_input = bert_tokenizer.tokenize(text)
    tokenize_text = bert_tokenizer.tokenize(text)
    sum_lp = 0.0
    for max_word_id in range((len(tokenize_input)-len(tokenize_text)), (len(tokenize_input))):
        sent = tokenize_input[:]
        input_ids = torch.tensor([bert_tokenizer.convert_tokens_to_ids(sent)])
        with torch.no_grad():
            outputs = bert_model(input_ids)
            next_token_logits = outputs[0] 
            #print(max_word_id,tokenize_input[max_word_id],outputs[0].shape)
        word_id = bert_tokenizer.convert_tokens_to_ids([tokenize_input[max_word_id]])[0]
        #print(word_id)
        predicted_prob = softmax(np.array(next_token_logits[0][0]))
        #lp = np.log(predicted_prob[word_id])
        lp = predicted_prob[word_id]
        sum_lp += lp
    return text,sum_lp
    
def bert_sent_scoreOLD(sent):
    text = "{} [SEP]".format(sent)
    input_ids = torch.tensor(bert_tokenizer.encode(text)).unsqueeze(0)  # Batch size 1
    #outputs = bert_model_next(input_ids)
    #score = outputs[0][0][0].item()
    #return str(score)

def bert_mask_list(sent,keywords):
    keys = [x.split(',') for x in keywords.split('|')]
    tokens = ['[CLS]']+sent.split()+['[SEP]']
    mask_index = tokens.index("[MASK]")
    indices = [i for i,val in enumerate(tokens) if val=="[MASK]"]
    results = []
    for index in indices:
        keyindex = indices.index(index)
        sentence = " ".join(tokens)
        input_ids = torch.tensor(bert_tokenizer.encode(sentence)).unsqueeze(0)
        outputs = bert_model(input_ids, masked_lm_labels=input_ids)
        pre = outputs[1].topk(10000)
        words = pre[1]
        best_words = words[0][index]
        scores = pre[0]
        best_scores = scores[0][index]
        #best_scores = np.array(best_scores) / np.sum(best_scores)
        predictions = [bert_tokenizer.convert_ids_to_tokens(x.tolist()) for x in best_words]
        res = zip(predictions,[x.item() for x in best_scores])
        results.append([(x[0],round(x[1],2)) for x in res if x[0] in keys[keyindex]])
    return results

def bert_mask_list_OLD(sent,words):
    sent = sent.split()
    target_index = sent.index('[MASK]')
    pre = " ".join(sent[:target_index])
    target = '[MASK]'
    post = " ".join(sent[target_index+1:])
    if 'mask' in target.lower():
        target=['[MASK]']
    else:
        target = bert_tokenizer.tokenize(target)
    tokens = ['[CLS]'] + bert_tokenizer.tokenize(pre)
    target_idx=len(tokens)
    #print(target_idx)
    tokens+=target+bert_tokenizer.tokenize(post)+['[SEP]']
    input_ids=bert_tokenizer.convert_tokens_to_ids(tokens)
    try:
        word_ids=bert_tokenizer.convert_tokens_to_ids(words)
    except KeyError:
        print("skipping bad wins")
        return None
    tens = torch.LongTensor(input_ids).unsqueeze(0)
    #print(tens)
    res = bert_model(tens)[0][0,target_idx]
    #print(res)
    #res=torch.nn.functional.softmax(res,-1)
    score = res[word_ids]
    scores = [str(float(x)) for x in score]
    result = zip(words, scores)
    return [x for x in result]


def xlnet_mask_predict(sent):
    sent = sent.split()
    target_index = sent.index('[MASK]')
    pre = " ".join(sent[:target_index])
    target = '[MASK]'
    post = " ".join(sent[target_index+1:])
    if 'mask' in target.lower():
        target=['[MASK]']
    else:
        target=xlnet_tokenizer.tokenize(target)
    tokens=['[CLS]']+xlnet_tokenizer.tokenize(pre)
    target_idx=len(tokens)
    #print(target_idx)
    tokens+=target+xlnet_tokenizer.tokenize(post)+['[SEP]']
    indexed_tokens=xlnet_tokenizer.convert_tokens_to_ids(tokens)

    segments_ids = [0] * len(tokens)
    # this is for the dummy first sentence. 
    segments_ids[0] = 0
    segments_ids[1] = 0
    tokens_tensor = torch.tensor([indexed_tokens])
    segments_tensors = torch.tensor([segments_ids])
    # Load pre-trained model (weights)

    # Predict all tokens
    predictions = xlnet_model(tokens_tensor, segments_tensors)
    predicted_index = torch.argmax(predictions[0][0, target_idx]).item()
    predicted_token = xlnet_tokenizer.convert_ids_to_tokens([predicted_index])
    #print(predicted_token)
    result = []
    #result.append(predicted_token)
    for i in range(50):
        predictions[0][0,target_idx,predicted_index] = -11100000
        predicted_index = torch.argmax(predictions[0][0, target_idx]).item()
        predicted_token = xlnet_tokenizer.convert_ids_to_tokens([predicted_index])
        res = predicted_token[0].replace('▁','')
        #print(res)
        result.append(res)
    if result:
        res1 = [x for x in result if x not in [':',',','.','-','"',')','(',';','...','?','!','в','’','“'] and len(x) > 1]
        if res1:
            return res1
        else:
            return 'None'    
    else:
        return 'None'
    

def xlnet_sent_scoreOLD(sent):
    text = "{} [SEP]".format(sent)
    input_ids = torch.tensor(xlnet_tokenizer.encode(text)).unsqueeze(0)  # Batch size 1
    outputs = xlnet_model_next(input_ids)
    score = outputs[0][0][0].item()
    return str(score)


def xlnet_mask_list(sent,words):
    words = words.split(',')
    sent = sent.split()
    target_index = sent.index('[MASK]')
    pre = " ".join(sent[:target_index])
    target = '[MASK]'
    post = " ".join(sent[target_index+1:])
    if 'mask' in target.lower():
        target=['[MASK]']
    else:
        target=xlnet_tokenizer.tokenize(target)
    tokens=['[CLS]']+xlnet_tokenizer.tokenize(pre)
    target_idx=len(tokens)
    #print(target_idx)
    tokens+=target+xlnet_tokenizer.tokenize(post)+['[SEP]']
    input_ids=xlnet_tokenizer.convert_tokens_to_ids(tokens)
    try:
        word_ids=xlnet_tokenizer.convert_tokens_to_ids(words)
    except KeyError:
        print("skipping bad wins")
        return None
    tens = torch.LongTensor(input_ids).unsqueeze(0)
    #print(tens)
    res = xlnet_model(tens)[0][0,target_idx]
    #print(res)
    #res=torch.nn.functional.softmax(res,-1)
    score = res[word_ids]
    scores = [str(float(x)) for x in score]
    result = zip(words, scores)
    return [x for x in result]

def gpt2(sent):
    indexed_tokens = gpt2_tokenizer.encode(sent)
    tokens_tensor = torch.LongTensor([indexed_tokens])
    with torch.no_grad():
        outputs = gpt2_model(tokens_tensor)
        pred = outputs[0].topk(50)      
    probabilities = torch.nn.functional.softmax(pred[0][-1])
    indices = pred[0]
    words = pred[1]
    words = [gpt2_tokenizer.decode([x.item()]) for x in words[-1,-1]]
    probablities = [torch.nn.functional.softmax(x) for x in indices[-1]]
    probs = [round(x*100,2) for x in probablities[-1].tolist()]
    logits = [x for x in pred[0][-1]]
    logits = logits[-1].tolist()
    result = zip(words,probs)
    return [x for x in result]


