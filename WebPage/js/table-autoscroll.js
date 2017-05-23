$(document).ready(function () {
    animate_tables();
    initAllAudio();
});

function animate_tables() {

    var table_animate_1 = $("#table-autoscroll-1");

    function anim1() {
        var st = table_animate_1.scrollTop();
        var sb = table_animate_1.prop("scrollHeight") - table_animate_1.innerHeight();
        table_animate_1.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, anim1);
    }

    anim1();

    var table_animate_2 = $("#table-autoscroll-2");

    function anim2() {
        var st = table_animate_2.scrollTop();
        var sb = table_animate_2.prop("scrollHeight") - table_animate_2.innerHeight();
        table_animate_2.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, anim2);
    }

    anim2();

    var table_animate_3 = $("#table-autoscroll-3");

    function anim3() {
        var st = table_animate_3.scrollTop();
        var sb = table_animate_3.prop("scrollHeight") - table_animate_3.innerHeight();
        table_animate_3.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, anim3);
    }

    anim3();

    var table_animate_4 = $("#table-autoscroll-4");

    function anim4() {
        var st = table_animate_4.scrollTop();
        var sb = table_animate_4.prop("scrollHeight") - table_animate_4.innerHeight();
        table_animate_4.animate({scrollTop: st < sb / 2 ? sb : 0}, 10000, anim4);
    }

    anim4();
}