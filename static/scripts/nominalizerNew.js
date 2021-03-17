$(document).ready(function() {
    $("#wshead").on('input click selectionchange propertychange keyup', function() {
        document.title = $("#wshead").text() + ' - FormalWriter';
        var currentText = $(this).text();
        $("#mytitle").text(currentText);
    });
    $("#wstext").on('input click selectionchange propertychange', function() {
        $("#wstext").css({
            'font-size': '18px'
        });
    });

    var regex = /\s+([.,!":])/g;
    $('#result').attr('contenteditable', 'false');
    var images = ['water1.png', 'water4.jpg'];
    $('.ui-block-c').css({
        'background-image': 'url(/static/images/' + images[Math.floor(Math.random() * images.length)] + ')'
    });

    $('#play').click(function() {
        const audio = new Audio("/static/sounds/done-for-you.mp3");
        audio.play();
    });

    const $valueSpan = $('.valueSpan2');
    const $value = $('#myrange');
    $valueSpan.html($value.val());
    $value.on('input change', function() {
        $valueSpan.html($value.val());
    });

    $('#close').click(function() {
        $('#close').hide();
        $('#sidebar').hide();
        $('#open').show();
    });
    $('#open').click(function() {
        $('#open').hide();
        $('#sidebar').show();
        $('#close').show();
    });
    $('#rightBarClose').click(function() {
        $('#rightBarClose').hide();
        $('#rightBar').hide();
        $('#rightBarOpen').show();
    });
    $('#rightBarOpen').click(function() {
        $('#rightBarOpen').hide();
        $('#rightBar').show();
        $('#rightBarClose').show();
    });

    $("#mycopy").click(function() {
        $.each($("select"), function() {
            var optionValue = $("option:selected").val();
            var replacedText = "<u>" + optionValue + "</u>";
            $(this).replaceWith(replacedText);
        });
        $.each($("del"), function() {
            $(this).replaceWith("");
        });
        cleanerVocab();
        procIt = CopyToClipboard('result');
        procIt = procIt.replace(regex, '$1');
        $("#result").html(procIt);
        //CopyToClipboard('result');
    });

    $("#myundo").click(function() {
        $("#result").html($("#proced").html());
    });

    $(window).scroll(function() {
        $('#firstRow').hide();
        $('#secondRow').css({
            'top': '0px',
            'background': '#f1f2ed'
        });
        $('#logoabv').show().css({
            'display': 'inline-block'
        });
        //$('.wsicons').css({'color':'#fafafa'});
    });


    var workspace = false;
    var worker = 'no worker';
    var timer;
    var timeout = 1000;

    $('#clearWS').on('click', function() {
        $('#wstext').html('').attr('data-placeholder', 'Continue to write here to add text');
    });

    $('#submitIcon').on('click', function() {
        clearTimeout(timer);
        if ($('#wstext').text()) {
            timer = setTimeout(function() {

                //AJAX CALL
                if (workspace == true) {
                    $('#lastwsd').show();
                } else {
                    $("#result").html(' ');
                }
                var myoptions = $('input[name=wsoptions]:checked', '#wsform').val();
                $("#sent").val($('#wstext').text());
                if (myoptions == "inform") {
                    workspace = true;
                    worker = 'inform';
                    pureAcad(workspace);
                } else if (myoptions == "nom") {
                    workspace = true;
                    worker = 'nom';
                    pureNom(workspace);

                } else if (myoptions == "para") {
                    workspace = true;
                    worker = 'para';
                    pureVocab(workspace);
                } else if (myoptions == "phrase") {
                    workspace = true;
                    worker = 'phrase';
                    purePhrase(workspace);
                } else if (myoptions == "nominal") {
                    workspace = true;
                    worker = 'nominal';
                    nominalMaker(workspace);
                }

            }, timeout);
        }
    });


}); // DOCUMENT READY

function cleanerVocab() {
    var keywords = [];
    $.each($("ul"), function() {
        var optionValue = $("li:selected").text();
        keywords.push(optionValue);
        var replacedText = "<u>" + optionValue + "</u>";
        $(this).replaceWith(replacedText);
    });
    $.each($("del"), function() {
        $(this).replaceWith("");
    });
    $("#cleanOutput").hide();
    return true;
}

function saveChanges() {
    var user = $("#myuser").val();
    var sent = $("#sent2").val();
    var proc = $("#proc").val();
    var cleaned = $("#cleaned").val();
    var data = $(this).serialize();
    $.ajax({
        type: "POST",
        dataType: "html",
        url: "/save",
        data: {
            cleaned: cleaned,
            sent: sent,
            proc: proc,
            user: user
        },
        success: function(data) {
            //getUser();
        }
    });
}


function runExample1() {
    $("#sent").val("The meaning of the word research means to search again or to examine carefully and to discover new facts (Hawkins, 1991 pg 438). Nurses don't ignore to use scientific knowledge to help improve their decision making and to provide the best possible care to patients and how to implement that care (Burns and Grove, 1995). ").css({
        'border': '1px solid #97a0bf'
    });

    $("#clearBox").show();
    $("#academize").show();
    $("#acadpop").hide();
    acad();
}

function runExample2() {
    $("#sent").val(' She was selected because she is educated.').css({
        'border': '1px solid #97a0bf'
    });
    $("#clearBox").show();
    $("#mybutton").show();
    $("#nompop").hide();
    nom();
}

function runExample3() {
    $("#clearBox").show();
    $("#mybutton").show();
    $("#headTitle").hide();
    $("#start").click();
    $("#sent").val('There is also the influence of economic factors to consider. Children are no longer economic assets').css({
        'border': '1px solid #97a0bf'
    });
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
        //$("#copied").show();
        var newtext = $("#result").text();
        $("#cleaned").val(newtext).hide();
        return $("#result").text()
    }
}


function pureAcad() {
    var sent = $("#sent").val();
    var user = $("#myuser").val();
    $('.wsloading').show();
    $("#tools").hide();
    $("#successful").hide();
    $("#copied").hide();
    var data = $(this).serialize();
    $.ajax({
        type: "POST",
        dataType: "html",
        url: "/academize",
        data: {
            sent: $('#sent').val(),
            wordlist: $('#wordlist').val(),
            myrange: $('#myrange').val(),
        },
        success: function(data) {
            $('.wsloading').hide();
            data = JSON.parse(data);
            console.log(data);
            if (data.result == 'None') {
                console.log("Here", data.textlength);
                if (data.textlength > 320) {
                    $("#103").show();
                } else {
                    $("#104").show();
                }
            } else if (data.result != 'None' && data.totalchange == 0) {
                $("#successful").html('<b>This is formal</b>').show();
                $("#result").html(data.result).show();
                $("#tools").show();

            } else {
                $("#result").html(data.result).show();
                $("#result").css({
                    'font-size': '20px',
                    'margin-top': '0px'
                });
                $("#successful").html("<b>Continue to write</b> or <b>select</b> the words and clean copy it to clipboard").show();
                $("#stats").show();
                $("#sent2").val(sent);
                $("#proc").val(data.result);
                $("#sent").val('');
                $("#tools").show();
                $('#play').click();
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

}

function pureNom() {
    var sent = $("#sent").val();
    var data = $(this).serialize();
    $(".wsloading").show();
    $("#result").html('').hide();
    $("#tools").hide();
    $("#copied").hide();
    $.ajax({
        type: "POST",
        dataType: "html",
        url: "/nomit",
        //url:"http://hega.lt.cityu.edu.hk:8001",
        //url:"http://metaphor.pro:8280",
        data: {
            sent: $('#sent').val()
        },
        success: function(data) {
            $(".wsloading").hide();
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
                    $("#result").append("<div id='anomhead'><p class='alert alert-info'>" + orig + "</p><div class='anom'>" + res[1] + "</div><br><div class='anom'>" + res[2] + "</div><br><div class='anom'>" + res[3] + "</div></div><br>").show();

                } else {

                    $("#result").append(orig).show().css({
                        'font-size': '18px'
                    });
                }


            }

        }
    });
    return false;
}

function pureVocab() {
    var sent = $("#sent").val();
    var user = $("#myuser").val();
    $(".wsloading").show();
    $("#tools").hide();
    $("#copied").hide();
    var data = $(this).serialize();
    $.ajax({
        type: "POST",
        dataType: "html",
        url: "/phrase",
        data: {
            sent: $('#sent').val(),
            wordlist: $('#wordlist').val(),
            myrange: $('#myrange').val(),
        },
        success: function(data) {
            $(".wsloading").hide();
            data = JSON.parse(data);
            $("#stats").show();

            if (data.result == 'None') {
                console.log("Here", data.textlength);
                if (data.textlength > 320) {
                    //alert("Text Too Long");
                    $("#103").show();
                } else {
                    $("#104").show();
                }
                $("#result").hide();
                $("#tools").hide();
            } else if (data.result != 'None' && data.totalchange == 0) {
                $("#successful").html('No Suggestion! Continue to write').show();
                $("#result").append(' ' + data.result).show();
                saveChanges();
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
            } else {
                saveChanges();
                $("#result").append(' ' + data.result).show();
                $('#result').attr('contenteditable', 'true');
                $("#successful").html('<b>Continue to write</b>').show();
                $('#wstext').html('').attr('data-placeholder', 'Continue to write here to add text');
                $("#sent2").val(sent);
                $("#proc").val(data.result);
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
            $items.each(function(index, item) {
                var $mainwords = $(this).find('.dropdown-toggle');
                $mainwords.each(function() {
                    myArray.push($(this))
                });
                var $mainitems = $(this).find('.dropdown-menu li a');
                $mainitems.each(function() {
                    $(this).on("click", function() {
                        $('.dropdown-toggle').eq(index).html($(this).text()).css({
                            'color': 'blue'
                        });
                    });
                });
            });

        }
    });
    event.preventDefault();
    return false;
}

function purePhrase() {
    var sent = $("#sent").val();
    var user = $("#myuser").val();
    $(".wsloading").show();
    $("#tools").hide();
    $("#copied").hide();
    var data = $(this).serialize();
    $.ajax({
        type: "POST",
        dataType: "html",
        url: "/phrase",
        data: {
            sent: $('#sent').val(),
            wordlist: $('#wordlist').val(),
            myrange: $('#myrange').val(),
        },
        success: function(data) {
            $(".wsloading").hide();
            data = JSON.parse(data);
            $("#stats").show();

            if (data.res == 'None') {
                console.log("Here", data.textlength);
                if (data.textlength > 320) {
                    //alert("Text Too Long");
                    $("#103").show();
                } else {
                    $("#104").show();
                }
                $("#result").hide();
                $("#tools").hide();
            } else {
                saveChanges();
                $("#result").append(' ' + data.res).show();
                $('#result').attr('contenteditable', 'true');
                $("#successful").html('<b>Continue to write</b>').show();
                $('#wstext').html('').attr('data-placeholder', 'Continue to write here to add text');
                $("#sent2").val(sent);
                $("#proc").val(data.res);
                $("#tools").show();
                $('#play').click();
            };

            var $items = $('.dropdown');
            var myArray = new Array();
            var myItems = new Array();
            $items.each(function(index, item) {
                var $mainwords = $(this).find('.dropdown-toggle');
                $mainwords.each(function() {
                    myArray.push($(this))
                });
                var $mainitems = $(this).find('.dropdown-menu li a');
                $mainitems.each(function() {
                    $(this).on("click", function() {
                        $('.dropdown-toggle').eq(index).html($(this).text()).css({
                            'color': 'blue'
                        });
                    });
                });
            });

        }
    });
    event.preventDefault();
    return false;
}

function nominalMaker() {
    var sent = $("#sent").val();
    var data = $(this).serialize();
    $(".wsloading").show();
    $("#result").html('').hide();
    $("#tools").hide();
    $("#copied").hide();
    $.ajax({
        type: "POST",
        dataType: "html",
        url: "/nominal_maker",
        data: {
            sent: $('#sent').val()
        },
        success: function(data) {
            $(".wsloading").hide();
            data = JSON.parse(data);
            console.log(data);
            var i;
            for (i = 0; i < data.length; i++) {
                error = data[i]["Errors"][0];
                orig = data[i]["Original"];
                res = data[i]["webColor"];
                tbl = data[i]["moveTable"];
                if (error > 0) {
                    console.log("HERE" + error);
                    $("#result").append("<div id='anomhead'><p class='alert alert-info'>" + orig + "</p><div class='anom'>" + data[i]["Result"][0] + "</div><br></div><br>").show();

                } else {
                    $("#result").append("<div id='anomhead'><p class='alert alert-info'>" + orig + "</p><div class='anom'>" + res[1] + "</div><br><div class='anom'>" + res[2] + "</div><br><div class='anom'>" + res[3] + "</div></div><br>").show();

                }
            }

        }
    });
    return false;
}
