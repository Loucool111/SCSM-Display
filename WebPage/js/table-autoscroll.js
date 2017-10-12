//Trigger à la fin du charhement de la page, quand le document est prêt
$(document).ready(function () {
    //Init du scroll auto des tableaux
    InitAutoscroll();

    //Init des sons
    InitAllAudio();

    //Auto refresh 60 secondes
    setTimeout(function () {
        window.location.reload(1);
    }, 60000);

    //Récupération du refresh time par défaut
    var time = $('#refresh-time').html();

    //Chaque seconde le timer est décrémenté
    setInterval(function () {
        if (time > 0) {
            time--;
            $('#refresh-time').html(time);
        }
    }, 1000);
});

function InitAutoscroll() {
    var Table3 = $("#table-autoscroll-3");

    function InitAutoscrollTable3() {
        var st = Table3.scrollTop();
        var sb = Table3.prop("scrollHeight") - Table3.innerHeight();
        Table3.animate({scrollTop: st < sb / 2 ? sb : 0}, 30000, InitAutoscrollTable3);
    }

    InitAutoscrollTable3();

    var Table4 = $("#table-autoscroll-4");

    function InitAutoscrollTable4() {
        var st = Table4.scrollTop();
        var sb = Table4.prop("scrollHeight") - Table4.innerHeight();
        Table4.animate({scrollTop: st < sb / 2 ? sb : 0}, 30000, InitAutoscrollTable4);
    }

    InitAutoscrollTable4();
}