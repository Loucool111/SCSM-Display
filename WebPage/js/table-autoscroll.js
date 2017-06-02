//Quand le document est prêt
$(document).ready(function () {
    //Init du scroll auto des tableaux
    InitAutoscroll();
    //Init des sons
    InitAllAudio();
    //Auto refresh 60 secondes
    setTimeout(function () {
        window.location.reload(1);
    }, 60000);
    
    var time = $('#refresh-time').html();
    setInterval(function (){
        time--;
        $('#refresh-time').html(time);
    }, 1000);
});

function InitAutoscroll() {

    var Table1 = $("#table-autoscroll-1");

    function InitAutoscrollTable1() {
        var st = Table1.scrollTop();
        var sb = Table1.prop("scrollHeight") - Table1.innerHeight();
        Table1.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, InitAutoscrollTable1);
    }

    InitAutoscrollTable1();

    var Table2 = $("#table-autoscroll-2");

    function InitAutoscrollTable2() {
        var st = Table2.scrollTop();
        var sb = Table2.prop("scrollHeight") - Table2.innerHeight();
        Table2.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, InitAutoscrollTable2);
    }

    InitAutoscrollTable2();

    var Table3 = $("#table-autoscroll-3");

    function InitAutoscrollTable3() {
        var st = Table3.scrollTop();
        var sb = Table3.prop("scrollHeight") - Table3.innerHeight();
        Table3.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, InitAutoscrollTable3);
    }

    InitAutoscrollTable3();

    var Table4 = $("#table-autoscroll-4");

    function InitAutoscrollTable4() {
        var st = Table4.scrollTop();
        var sb = Table4.prop("scrollHeight") - Table4.innerHeight();
        Table4.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, InitAutoscrollTable4);
    }

    InitAutoscrollTable4();
}