# formalwriter
To deploy, first install the dependencies:

 > Flask<br>
 > Spacy and English language model with spacy.load('en_core_web_sm')<br> 
 > NTLK<br> 
 > Cython<br> 
 > Transformers<br>
 
and other dependencies reqired in your environment<br>
Then run the server with:

> cd acadnomClass<br> 
> python3 setup.py build_ext --inplace<br> 
> cd ..<br> 
> python3 app.py

@Anton: I will prepare the Docker version and I will write a complete readme file later. Please check to see if it looks ok. 
