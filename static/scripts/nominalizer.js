$(document).ready(function(){  
 $("#wshead").on('input click selectionchange propertychange', function() {
	document.title = $("#wshead").text()+' - FormalWriter';
});
    $("#wstext").on('input click selectionchange propertychange', function() {
		$("#wstext").css({'font-size':'18px'});
    });

	var timer;
	var timeout = 1000;
	$('#wstext').keyup(function(){
	    clearTimeout(timer);
	    if ($('#wstext').text()) {
		timer = setTimeout(function(){
					
		//AJAX CALL

		var myoptions = $('input[name=wsoptions]:checked', '#wsform').val();
		$("#sent").val($('#wstext').text());
		if (myoptions == "inform"){
				pureAcad();
			} else if (myoptions == "nom") {
				pureNom();

			} else if (myoptions == "para") {
				pureVocab();
			}

				}, timeout);
			}
		});


	  const $valueSpan = $('.valueSpan2');
	  const $value = $('#customRange11');
	  $valueSpan.html($value.val());
	  $value.on('input change', () => {

	    $valueSpan.html($value.val());
	  });

	//WorkSpace Stops Here

	var regex = /\s+([.,!":])/g;
       $("#loading").hide();
	$("#mybutton").hide();
	$(".myarea").css({'border':'1px solid #e0e0dc'});
	$('#result').attr('contenteditable','false');
	var images = ['water1.png', 'water4.jpg'];
       $('.ui-block-c').css({'background-image': 'url(/static/images/' + images[Math.floor(Math.random() * images.length)] + ')'});
	//$('#result').scrollTop($('#result')[0].scrollHeight);

    $("#sent").change(function() {
        $("#clearBox").show();
    });

	$("#mainfooter").show();

$('#play').click(function() {
  const audio = new Audio("/static/sounds/done-for-you.mp3");
  audio.play();
});



    $("#start").on("click",function(e){
	getUser();
	$("#start").hide();
	$("#mainMenu").hide();
	$("#bolckCBar").hide();
	$("#startNote").hide();
        $("#sent").val('');
	$("#allresults").hide();
	$("#mybutton").hide();
	$("#academize").show();
	$("#user-history").show();
	$("#sent").show();
	$("#settings").show();
        $("#nom-bar").hide();
	$("#block-a").css({'border':'none','background':'none'});
	$("#block-b").css({'border':'none','background':'none'});
	$("#block-c").css({'border':'none','background':'none'});
	$("#mylist").show();
	$("#sent").css({'border':'none'});
	$("#welldone").hide();
	$("#originalHead").hide();
	$("#original").hide();
	$("#resultHead").hide();
	$("#resultCover").hide();
	$("#resultError").hide();
	$("#result").hide();
	$("#result1").hide();
	$("#result2").hide();
	$("#result3").hide();
	$("#result4").hide();
	$("#cleanOutput").hide();
	$("#cleanCopy").hide();
	$("#smallNote").hide();
	$("#stats").hide();
	$(".inst").show();
	$("#announce").show();
	$("#copied").hide();
	$('#proceedC').hide();
	$("#cutomMode").hide();
	$("#success").hide();
	$("#successful").hide();
	$("#headTitle").hide();
	$('#result').attr('contenteditable','false');
    });

    $("#clearBox").on("click",function(e){
	$("#mylist").show();
        $("#sent").val('');
	$("#start").hide();
	$("#startNote").hide();
	$("#allresults").hide();
	$("#mybutton").hide();
	$("#academize").show();
	$("#sent").css({'border':'none'});
	$("#welldone").hide();
	$("#originalHead").hide();
	$("#original").hide();
	$("#resultHead").hide();
	$("#resultCover").hide();
	$("#resultError").hide();
	$("#result1").hide();
	$("#result2").hide();
	$("#result3").hide();
	$("#result4").hide();
	$("#stats").hide();
	$(".inst").show();
	$("#announce").show();
	$("#copied").hide();
	$('#proceedC').hide();
	$("#cutomMode").hide();
	$("#success").hide();
	$("#headTitle").hide();
    });

    $(".myarea").on('input click selectionchange propertychange', function() {
	//$("#sent").css({'box-shadow':'0 2px 0 0 #ccc'});
	$("#mybutton").show();
	$("#academize").show();
	$("#clearBox").show();
	$("#settings").show();
    });

    $("#jcodeHead").on('click', function() {
	$("#feedback").hide();
	$("#jcode").toggle();
});

$("#mylist").on('click', function() {
        if($(".userh").is(":visible")){
	} else {
	$("#start").click(); 
	}

    });


$("#feedbackHead").click(function(){
	$("#jcode").hide();
	$("#feedback").toggle();
});  

 $("#cleanOutput").click(function(){
        $.each($("select"), function(){            
            var optionValue = $("option:selected").val();
            var replacedText = "<u>"+optionValue+"</u>";
	    $(this).replaceWith(replacedText);
        });
        $.each($("del"), function(){            
            $(this).replaceWith("");
        });
	//cannot();
	$("#cleanOutput").hide();
	var myhtml = $('#result').html();
	var htmloutput = myhtml.replace(regex, '$1');
	$('#result').html(htmloutput);
 	$('#result').attr('contenteditable','true');
	$("#cleanCopy").show();
	$("#checkVocab").show();
	//$("#cleanCopyVocab").show().click();
    });   

$("#mycopy").click(function(){

        $.each($("select"), function(){            
            var optionValue = $("option:selected").val();
            var replacedText = "<u>"+optionValue+"</u>";
	    $(this).replaceWith(replacedText);
        });
        $.each($("del"), function(){            
            $(this).replaceWith("");
        });

         cleanerVocab();
	 procIt = CopyToClipboard('result');
         procIt = procIt.replace(regex, '$1');
	 $("#result").html(procIt);
	 CopyToClipboard('result');
});
$("#myundo").click(function(){
         $("#result").html($("#proced").html());
});

 $("#cleanOutputVocab").click(function(){
        $.each($("select"), function(){            
            var optionValue = $("option:selected").val();
            var replacedText = "<u>"+optionValue+"</u>";
	    $(this).replaceWith(replacedText);
        });
        $.each($("del"), function(){            
            $(this).replaceWith("");
        });
	//cannot();
	$("#cleanOutput").hide();
	$("#cleanOutputVocab").hide();
	var myhtml = $('#result').html();
	var htmloutput = myhtml.replace(regex, '$1');
	$('#result').html(htmloutput);
 	$('#result').attr('contenteditable','true');
	$("#cleanCopy").hide();
	$("#cleanCopyVocab").hide();
	$("#checkVocab").hide();
	$("#cleanCopyVocab").show().click();
    });   

$("#checkVocab").click(function(){
	$("#checkVocab").hide();
	var mytext = $('#result').text();
	$("#sent").val(mytext);
	vocab();
});
 
$("#cleanCopy").click(function(){
        var mytext = $('#result').text();
	var textoutput = mytext.replace(regex, '$1');
	$('#result').html(textoutput);
        $("#cleaned").val(textoutput);
	cleanerVocab();
	CopyToClipboard('result');
        
});

$("#cleanCopyVocab").click(function(){
         cleanerVocab();
	 procIt = CopyToClipboard('result');
         procIt = procIt.replace(regex, '$1');
	 $("#result").html(procIt);
	 CopyToClipboard('result');
});


$("#autogen").click(function(){
	var sent = $("#sent").val();
	$("#welldone").hide();
	$("#cleanOutput").hide();
	$("#copied").hide();
	$("#result").hide();
	$("#autoMode").show();
	$("#cutomMode").hide();
	$("#success").hide();
	res = generate(sent,"auto");
	data = JSON.parse(res);
	res = data.result;
	comm = data.comment;
if(data.result == 'None'){
	if (data.textlength > 205){
		$("#103").show();
		$(".st2").html(data.textlength).show();
		$("#autoMode").hide();
		$("#cutomMode").hide();
	} else {
		$("#104").show();
	}
		$("#result").hide();
		$("#cleanOutput").hide();
		$("#smallNote").hide();  
} else {
	$("#result1").html(res).hide();
	var aaa = cleanerOne();
	if (comm == "nonacad") {
		mynewtext = $('#result1').text(); 
		$('#result1').html(mynewtext);
		res2 = generate(mynewtext);
		data2 = JSON.parse(res2);
		$("#result").html(data2.result).show();
		var bbb = cleanerTwo();
		$("#success").show();
		$("#autoMode").hide();
		$("#cleanCopy").show();
	} else {
		$("#result").html(res).show();
		var ccc = cleanerTwo();
		$("#success").show();
		$("#autoMode").hide();
		$("#cleanCopy").show();
	}
}
});

$("#custombt").click(function(){
	$("#welldone").hide();
	$("#cleanOutput").hide();
	$("#copied").hide();
	$("#result").hide();
	$("#cutomMode").show();
	$("#autoMode").hide();
	$("#success").hide();
 	var sent = $("#sent").val();
	res = generate(sent,"custombt");
	data = JSON.parse(res);
	res = data.result;
	comm = data.comment;
if(data.result == 'None'){
	if (data.textlength > 105){
		$("#103").show();
		$(".st2").html(data.textlength).show();
		$("#autoMode").hide();
		$("#cutomMode").hide();
	} else {
		$("#104").show();
	}
		$("#result").hide();
		$("#cleanOutput").hide();
		$("#smallNote").hide();  
} else {
	if (comm == "nonacad") {
		$("#welldone").show();
		$("#result").html(res).show();
		$('#proceedC').show();
		$("#proceedC").click(function(){
			cleanerTwo(); 
			$('#proceedC').hide();
			mynewtext = $("#result").text();
			res2 = generate(mynewtext);
			data2 = JSON.parse(res2);
			$("#result").html(data2.result).show();
			$("#cleanOutput").show();
			$("#cutomMode").hide();
			$("#success").show();
		});
	
	} else {
		$("#result").html(res).show();
		$("#cleanOutput").show();
		$("#cutomMode").hide();
		$("#success").show();
	}
}
});

function cleanerOne(){
	var keywords = [];
       $.each($("select"), function(){            
            var optionValue = $("option:selected").val();
	    keywords.push(optionValue);
            var replacedText = "<u>"+optionValue+"</u>";
	    $(this).replaceWith(replacedText);
        });
        $.each($("del"), function(){            
            $(this).replaceWith("");
        });
	$("#cleanOutput").hide();
return true;
}

function cleanerTwo(){
	var keywords = [];
       $.each($("select"), function(){            
            var optionValue = $("option:selected").val();
	    keywords.push(optionValue);
            var replacedText = "<span style='color:green'>"+optionValue+"</span>";
	    $(this).replaceWith(replacedText);
        });
        $.each($("del"), function(){            
            $(this).replaceWith("");
        });
	$("#cleanOutput").hide();
return keywords;
}

function cleanerVocab(){
	var keywords = [];
       $.each($("ul"), function(){            
            var optionValue = $("li:selected").text();
	    keywords.push(optionValue);
            var replacedText = "<u>"+optionValue+"</u>";
	    $(this).replaceWith(replacedText);
        });
        $.each($("del"), function(){            
            $(this).replaceWith("");
        });
	$("#cleanOutput").hide();
return true;
}




function generate(mytext,genbut){
	$("#result").hide();
	$("#welldone").hide();
	$("#loading").show();
	$("#cleanOutput").hide();
	$("#cleanCopy").hide();
	$("#smallNote").hide();
	$("#result").html('');
	$("#103").hide();
	$("#104").hide();
	var data = $(this).serialize();
    	$.ajax({
            type:"POST",
            dataType:"html",
            url:"/generator",
            data:{sent: mytext, genbut:genbut},
	    async: false,
            success:function(data)
                {
                $("#loading").hide();
		res = data;
                }
	
            });
	
return res;
}

    
}); // DOCUMENT READY

function cannot(){

$("#result").each(function() {
    var text = $(this).text();
    text = text.replace("ca  not", "cannot");
    $(this).text(text);
});
}

function nom(){
    var sent = $("#sent").val();
	$("#announce").hide();
	$("#headTitle").hide();
	$("#allresults").show();
   	$("#result").html('');
	$("#result1").html('');
	$("#result2").html('');
	$("#result3").html('');
	$("#result4").html('');
	$(".error").hide();
	$(".inst").hide();
	$("#smallNote").hide();
	$("#loading").show();
	$("#jcodeHead").hide();
	$("#feedbackHead").hide();
	$("#question").hide();
	$("#instruction").hide();
	$("#originalHead").hide();
	$("#original").hide();
	$("#resultHead").hide();
	$("#academize").show()
	var data = $(this).serialize();
    	$.ajax({
            type:"POST",
            dataType:"html",
            //url:"/nomit",
            url:"http://hega.lt.cityu.edu.hk:8001",
            //url:"http://metaphor.pro:8280",
            data:{text: $('#sent').val()},
            success:function(data)
                {
		$("#loading").hide();
		$("#announce").hide();
		$(".inst").show();
		$("#resultCover").show();
		$("#originalHead").show();
		$("#resultHead").show();
		$(".ui-block-c").css({'background-image':'none'});
		$(".ui-block-b").css({'background-color':'none'});
		data = JSON.parse(data);

var i;
for (i = 0; i < data.length; i++) {
     error = data[i]["Errors"][0];
     orig = data[i]["Original"];
     res = data[i]["webColor"];
     tbl = data[i]["moveTable"];
if (error != 0) {
$("#original").html(orig[0]).show();
$("#resultError").html(data[i]["Result"][0]).show();
$("#"+error).show();


} else {
$("#original").html(res[0]).show().css({'font-size':'17px'});
$("#result1").html(res[1]).show().css({'font-size':'17px'});
$("#result2").html(res[2]).show().css({'font-size':'17px'});
$("#result3").html(res[3]).show().css({'font-size':'17px'});

} 
     } 

     }
            });
    return false;
}

function saveChanges(){
var user = $("#myuser").val();
var sent = $("#sent2").val();
var proc = $("#proc").val();
var cleaned = $("#cleaned").val();
var data = $(this).serialize();
    	$.ajax({
	    type:"POST",
            dataType:"html",
            url:"/save",
            data:{cleaned:cleaned,sent:sent,proc:proc,user:user},
            success:function(data) {
		//getUser();
}
});
}

function getUser(){
var username = $("#myuser").val();
console.log("inside up");
var myuserResults = [];
$.ajax({
	    type:"GET",
            dataType:"html",
            url:"/user",
            data:{username:username},
            success:function(data) {
		userData = JSON.parse(data);
		userRes = userData.res;
		console.log("got res");
		console.log(userRes);
	if (userRes && userRes.length > 0) {
		
		$.each(userRes, function(i, item) {
			var $d = $('<div>');
			$d.attr("class","userh");
			var outRes = userRes[i][2];
			var shortText = outRes.slice(0,70) + "...";
			var myNum = i+1;
			var myheader = "<span style='font-family:Lato, sans-serif;color:#e2534f;font-size:14px;'><b>Text: "+myNum+"</b></span><a href='#'><span class='glyphicon glyphicon-trash' data-role='none' style='float:right' oclick='delRec("+i+");'></span></a><hr>";
			$d.html(myheader+shortText);
			myuserResults.push($d.html(myheader+shortText));
			$('#user-history').append($d);

				$d.click(function(){ 

					$('#user-history').css({'position':'absolute','margin-top':'550px','height':'200px','width':'40%','margin-left':'20px'});
					$('#result').attr('contenteditable','false');
					$("#result").css({'margin-top':'30px','height':'450px','font-size':'18px'}).html(userRes[i][3]).show();
					$('#result').attr('contenteditable','false');
					$("#editorCtl").css({'position':'relative','top':'40px'});
					$("#sent").val(outRes);
					$("#successful").show();
					$("#histTitle").hide();
					$("#editorCtl").show();
					$("#cleanOutput").show();
					$("#smallNote").show();
					$('#result').attr('contenteditable','true');
					var $items = $('.dropdown');
					var myArray = new Array();
					var myItems = new Array();
					$items.each(function(index,item){
						var $mainwords = $(this).find('.dropdown-toggle');
						$mainwords.each(function(){myArray.push($(this))});
						var $mainitems = $(this).find('.dropdown-menu li a');
						$mainitems.each(function(){
							$(this).on("click",function(){ 
								$('.dropdown-toggle').eq(index).html($(this).text()).css({'color':'blue'});
							 });
						});
					});


 				});



		});
}
}

});
return myuserResults;
}

function acad(){
    var sent = $("#sent").val();
    var user = $("#myuser").val();
	$('#result').css({'min-height':'400px','margin-top':'30px',});
        $('#user-history').hide();
	$("#checkVocab").hide();
	$("#cleanOutput").hide();
	$("#cleanOutputVocab").hide();
	$('#sent').prop("required", true);
	$("#welldone").hide();
	$("#loading").show();
	$("#cleanOutput").hide();
	$("#cleanCopy").hide();
	$("#smallNote").hide();
	$("#result").html('');
	$("#103").hide();
	$("#104").hide();
	$("#successful").hide();
	$("#copied").hide();
$('#result').attr('contenteditable','false');
	var data = $(this).serialize();
    	$.ajax({
            type:"POST",
            dataType:"html",
            url:"/academize",
            data:{sent: $('#sent').val(),wordlist: $('#wordlist').val(),myrange: $('#myrange').val(),},
            success:function(data)
                {
		$("#loading").hide();
		$("#cleanOutput").show();
		$("#clearBox").show();
                $("#smallNote").show();  
		$(".inst").hide()
		$("#sent").css({'border':'none'});
                data = JSON.parse(data);
		//$("#original").html(data.orig).hide();
		$(".ui-block-c").css({'background-image':'none'});
		$(".ui-block-b").css({'background-color':'none'});
		$("#block-c").css({'background-image':'none'});
		$("#block-b").css({'background-color':'none'});
		$("#headTitle").hide();
		$("#stats").show();
		$("#academize").hide()
		$("#settings").hide()
$("#clearBox").hide();
if(data.result == 'None'){
	console.log("Here", data.textlength);
	if (data.textlength > 320){
		//alert("Text Too Long");
		$("#103").show();
	} else {
		$("#104").show();
	}
$("#result").hide();
$("#cleanOutput").hide();
$("#smallNote").hide();  
}
else if(data.result != 'None' && data.totalchange == 0){
$("#103").hide();
$("#104").hide();
$("#welldone").show();
$("#cleanOutput").hide();
$("#result").css({'font-size':'18px','margin-top':'40px'}).show().html(data.result);
$("#editorCtl").css({'margin-top':'40px'});
$$("#cleanCopy").hide();
$("#cleanCopyVocab").hide();
$("#checkVocab").show();
} else {
$("#103").hide();
$("#104").hide();
$("#result").html(data.result).show();
$("#result").css({'font-size':'18px','margin-top':'40px'});
$("#editorCtl").css({'margin-top':'40px'});
$("#successful").show();
$("#sent2").val(sent);
$("#proc").val(data.result);
$("#sent").val('');
saveChanges();
};
	$("#user").html(data.username).show();
	$("#st1").html(data.totalchange).show();
	$(".st2").html(data.textlength).show();
	$("#st3").html(data.convertlength).show();
	$("#st4").html(data.abrlength).show();
	$("#st5").html(data.fullconversion).show();
	$("#st6").html(data.acadlength).show();
	$("#st7").html(data.nonacadlength).show();
	$("#st8").html(data.acadperc).show();
	$("#st9").html(data.nonacadperc).show();
                }
            });
event.preventDefault();
    return false;
}


function createTable(tableData) {
    var tableId = "tab1";
    var tableName = "tab1";
    var tableRows  = tableData;
    
		// create table
    $('#result4').append('<table border="1" id="' + tableId + '" name="' + tableName + '"></table>');
    
    // create title
    $('#'+tableId).append('<caption>' + tableTitle + '</caption>');
    
    // create rows
    for (var i = 0; i < tableRows.length; i++) {
        createRow(tableId, tableRows[i]);
    }
}

function createRow(table_id, rowData) {
    var row = $("<tr />")
    $("#"+table_id).append(row);
    
    // create cells inside this row
    for (var i = 0; i < rowData.length; i++) {

    	row.append($("<td>" + rowData[i] + "</td>"));
    }
}
function runExample1(){
	$("#sent").val("The meaning of the word research means to search again or to examine carefully and to discover new facts (Hawkins, 1991 pg 438). Nurses don't ignore to use scientific knowledge to help improve their decision making and to provide the best possible care to patients and how to implement that care (Burns and Grove, 1995). ").css({'border':'1px solid #97a0bf'});

	$("#clearBox").show();
	$("#academize").show();
	$("#acadpop").hide();
	acad();
}
function runExample2(){
	$("#sent").val(' She was selected because she is educated.').css({'border':'1px solid #97a0bf'});
	$("#clearBox").show();
	$("#mybutton").show();
	$("#nompop").hide();
	nom();
}
function runExample3(){
	$("#clearBox").show();
	$("#mybutton").show();
	$("#headTitle").hide();
	$("#start").click();
	$("#sent").val('There is also the influence of economic factors to consider. Children are no longer economic assets').css({'border':'1px solid #97a0bf'});
	vocab();
}


function CopyToClipboard(containerid) {
   $("#copied").hide();
  if (document.selection) {
    var range = document.body.createTextRange();
    range.moveToElementText(document.getElementById(containerid));
    range.select().createTextRange();
    document.execCommand("copy");
  } else if (window.getSelection) {
    var range = document.createRange();
    range.selectNode(document.getElementById(containerid));
    window.getSelection().addRange(range);
    document.execCommand("copy");
    $("#successful").html("Done!");
    $("#copied").show();
    var newtext = $("#result").text();
    $("#cleaned").val(newtext).hide();
    return newtext
  }
}

function vocab(){
    var sent = $("#sent").val();
    var user = $("#myuser").val();
	$('#result').css({'min-height':'400px','margin-top':'30px',});
	$('#sent').prop("required", true);
	$("#myfooter").hide();
	$("#user_history").hide();
	if ($('#successful').is(':visible')) {
		$("#editorCtl").hide();
		$("#loading").show().css({'position':'absolute','left':'50%','margin-top':'10px','z-index':'1','width':'70%'});
		$('#successful').html('<b>Please wait...</b> still you can edit your text below');
	} else {
	$("#result").html('');
        $('#user-history').hide();
	$("#welldone").hide();
	$("#loading").show();
	$("#cleanOutput").hide();
	$("#cleanCopy").hide();
	$("#cleanCopyVocab").hide();
	$("#smallNote").hide();
	$("#103").hide();
	$("#104").hide();
	$("#successful").hide();
	$("#copied").hide();
        $('#result').attr('contenteditable','false');
	$('#longMode').show();
	}

	var data = $(this).serialize();
    	$.ajax({
            type:"POST",
            dataType:"html",
            url:"/vocab",
            data:{sent: $('#sent').val(),wordlist: $('#wordlist').val(),myrange: $('#myrange').val(),},
            success:function(data)
                {
		$("#loading").hide();
		$("#cleanOutput").show();
		$("#clearBox").show();
                $("#smallNote").show();  
		$(".inst").hide()
		$("#sent").css({'border':'none'});
                data = JSON.parse(data);
		//$("#original").html(data.orig).hide();
		$(".ui-block-c").css({'background-image':'none'});
		$(".ui-block-b").css({'background-color':'none'});
		$("#block-c").css({'background-image':'none'});
		$("#block-b").css({'background-color':'none'});
		$("#headTitle").hide();
		$("#stats").show();
		$("#academize").hide()
		$("#settings").hide()
                $("#clearBox").hide();

if(data.result == 'None'){
	console.log("Here", data.textlength);
	if (data.textlength > 320){
		//alert("Text Too Long");
		$("#103").show();
	} else {
		$("#104").show();
	}
$("#result").hide();
$("#cleanOutput").hide();
$("#smallNote").hide();  
}
else if(data.result != 'None' && data.totalchange == 0){
$("#103").hide();
$("#104").hide();
$("#welldone").hide();
$("#cleanOutput").hide();
$('#result').attr('contenteditable','true');
$("#result").css({'font-size':'18px','margin-top':'40px'}).show().append(" "+data.result);
$("#editorCtl").css({'margin-top':'40px'});
$("#cleanCopy").hide();
$("#cleanCopyVocab").hide();
$("#checkVocab").show();
$('#longMode').hide();
$("#successful").show().html('Done. No word suggestion. Continue to write');
$("#cleanCopyVocab").show();
saveChanges();

} else if (data.result != 'None' && data.totalchange > 0 && $('#successful').is(':visible')) {
	saveChanges();
	$("#result").append(' '+data.result).show();
	$('#result').attr('contenteditable','true');
	$("#clearBox").click();
	$("#checkVocab").hide();
	$("#cleanOutput").hide();
	$("#cleanOutputVocab").hide();
	$("#editorCtl").show();
	$("#cleanCopyVocab").show();
	$("#successful").html('<b>Continue to write</b>');
	$('#play').click();
	$("#myfooter").hide();
	$("#sent2").val(sent);
	$("#proc").val(data.result);
} else {
$("#103").hide();
$("#104").hide();
$("#result").html(data.result).show();
$("#result").css({'font-size':'20px','margin-top':'40px'});
$("#editorCtl").css({'margin-top':'40px'});
$("#successful").show();
$("#checkVocab").hide();
$("#cleanOutput").hide();
$("#cleanOutputVocab").show();
$("#cleanCopyVocab").show();
$("#sent2").val(sent);
$("#proc").val(data.result);
$("#sent").val(sent);
saveChanges();
$('#longMode').hide();
$('#play').click();
$('#result').attr('contenteditable','true');
};
	$("#user").html(data.username).show();
	$("#st1").html(data.totalchange).show();
	$(".st2").html(data.textlength).show();
	$("#st3").html(data.convertlength).show();
	$("#st4").html(data.abrlength).show();
	$("#st5").html(data.fullconversion).show();
	$("#st6").html(data.acadlength).show();
	$("#st7").html(data.nonacadlength).show();
	$("#st8").html(data.acadperc).show();
	$("#st9").html(data.nonacadperc).show();


var $items = $('.dropdown');
var myArray = new Array();
var myItems = new Array();
$items.each(function(index,item){
        var $mainwords = $(this).find('.dropdown-toggle');
        $mainwords.each(function(){myArray.push($(this))});
	var $mainitems = $(this).find('.dropdown-menu li a');
	$mainitems.each(function(){
		$(this).on("click",function(){ 
			$('.dropdown-toggle').eq(index).html($(this).text()).css({'color':'blue'});
		 });
	});
});






                }
            });
event.preventDefault();
    return false;
}

function pureAcad(){
    var sent = $("#sent").val();
    var user = $("#myuser").val();
    $('#wsloading').show();
    $("#tools").hide();
    if ($('#successful').is(':visible')) {
	} else {   $("#result").html('');
}

    var data = $(this).serialize();
    	$.ajax({
            type:"POST",
            dataType:"html",
            url:"/academize",
            data:{sent: $('#sent').val(),wordlist: $('#wordlist').val(),myrange: $('#myrange').val(),},
            success:function(data)
                {
    		$('#wsloading').hide();

		$('#wstext').html('').attr('data-placeholder','Continue to write here to add text');
                data = JSON.parse(data);

if(data.result == 'None'){
	console.log("Here", data.textlength);
	if (data.textlength > 320){
		$("#103").show();
	} else {
		$("#104").show();
	}
}
else if(data.result != 'None' && data.totalchange == 0){
$("#successful").html('Well done. This is formal').show();
$("#result").append(data.result).show();
$("#tools").show();
} else {
$("#result").append(data.result).show();
$("#result").css({'font-size':'20px','margin-top':'0px'});
$("#successful").show();
$("#stats").show();
$("#sent2").val(sent);
$("#proc").val(data.result);
$("#sent").val('');
$("#tools").show();
saveChanges();
};
	$("#user").html(data.username).show();
	$("#st1").html(data.totalchange).show();
	$(".st2").html(data.textlength).show();
	$("#st3").html(data.convertlength).show();
	$("#st4").html(data.abrlength).show();
	$("#st5").html(data.fullconversion).show();
	$("#st6").html(data.acadlength).show();
	$("#st7").html(data.nonacadlength).show();
	$("#st8").html(data.acadperc).show();
	$("#st9").html(data.nonacadperc).show();
                }
            });
event.preventDefault();
    return false;
}

function pureNom(){
    var sent = $("#sent").val();
    var data = $(this).serialize();
	$("#wsloading").show();
	$("#result").html('').hide();
	$("#tools").hide();
    	$.ajax({
            type:"POST",
            dataType:"html",
            url:"/nomit",
            //url:"http://hega.lt.cityu.edu.hk:8001",
            //url:"http://metaphor.pro:8280",
            data:{sent: $('#sent').val()},
            success:function(data)
                {
		$("#wsloading").hide();
		data = JSON.parse(data);
console.log(data.length);
var i;
for (i = 0; i < data.length; i++) {
     error = data[i]["Errors"][0];
     orig = data[i]["Original"];
     results = data[i]["Result"];
     res = data[i]["webColor"];
     tbl = data[i]["moveTable"];
     console.log(results);
	if (results[0] != "notCause") {
$("#result").append("<div id='anomhead'><p class='alert alert-info'>"+orig+"</p><div class='anom'>"+res[1]+"</div><br><div class='anom'>"+res[2]+"</div><br><div class='anom'>"+res[3]+"</div></div><br>").show();
		     
	} else {
		
		$("#result").append(orig).show().css({'font-size':'18px'});
	}


     } 

     }
            });
    return false;
}

function pureVocab(){
    var sent = $("#sent").val();
    var user = $("#myuser").val();
	$("#wsloading").show();
	$("#tools").hide();

    if ($('#successful').is(':visible')) {
	$('#successful').html('').removeClass('alert alert-info');
	} else {
	$("#result").html('');
	}
	var data = $(this).serialize();
    	$.ajax({
            type:"POST",
            dataType:"html",
            url:"/vocab",
            data:{sent: $('#sent').val(),wordlist: $('#wordlist').val(),myrange: $('#myrange').val(),},
            success:function(data)
                {
		$("#wsloading").hide();
                data = JSON.parse(data);
		$("#stats").show();

if(data.result == 'None'){
	console.log("Here", data.textlength);
	if (data.textlength > 320){
		//alert("Text Too Long");
		$("#103").show();
	} else {
		$("#104").show();
	}
$("#result").hide();
$("#tools").hide(); 
}
else if(data.result != 'None' && data.totalchange == 0){
$("#successful").show().html('Done. No word suggestion. Continue to write').addClass('alert alert-info');
$("#result").append(' '+data.result).show();
saveChanges();

} else if (data.result != 'None' && data.totalchange > 0 && $('#successful').is(':visible')) {
	saveChanges();
	$("#result").append(' '+data.result).show();
	$('#result').attr('contenteditable','true');
	$("#successful").html('<b>Continue to write</b>').addClass('alert alert-info');
	$('#wstext').html('').attr('data-placeholder','Continue to write here to add text');
	$('#play').click();
	$("#sent2").val(sent);
	$("#proc").val(data.result);
	$("#tools").show();
	$('#play').click();

} else {
$("#103").hide();
$("#104").hide();
$('#wstext').html('').attr('data-placeholder','Continue to write here to add text');
$("#result").html(data.result).show();
$("#result").css({'font-size':'20px','margin-top':'-20px'});
$("#successful").show();
$("#sent2").val(sent);
$("#proc").val(data.result);
$("#proced").html(data.result);
$("#sent").val(sent);
saveChanges();
$('#longMode').hide();
$('#play').click();
$('#result').attr('contenteditable','true');
$("#tools").show();
$('#play').click();
};
	$("#user").html(data.username).show();
	$("#st1").html(data.totalchange).show();
	$(".st2").html(data.textlength).show();
	$("#st3").html(data.convertlength).show();
	$("#st4").html(data.abrlength).show();
	$("#st5").html(data.fullconversion).show();
	$("#st6").html(data.acadlength).show();
	$("#st7").html(data.nonacadlength).show();
	$("#st8").html(data.acadperc).show();
	$("#st9").html(data.nonacadperc).show();


var $items = $('.dropdown');
var myArray = new Array();
var myItems = new Array();
$items.each(function(index,item){
        var $mainwords = $(this).find('.dropdown-toggle');
        $mainwords.each(function(){myArray.push($(this))});
	var $mainitems = $(this).find('.dropdown-menu li a');
	$mainitems.each(function(){
		$(this).on("click",function(){ 
			$('.dropdown-toggle').eq(index).html($(this).text()).css({'color':'blue'});
		 });
	});
});

                }
            });
event.preventDefault();
    return false;
}



