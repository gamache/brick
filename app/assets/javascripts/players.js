if (!Brick) var Brick = {};

if (!Brick.Player) Brick.Player = {};

Brick.Player.render_graphs = function (stats) {
  var overall = stats.shift;
  var player_name = stats[0]['player'];
  var year_list = [];
  var warps_list = [];

  for (var i in stats) {
    var stat = stats[i];
    year_list.push(stat['year']);
    warps_list.push(stat['warps']);
  }

  var warps_chart = new Highcharts.Chart({
    chart: {
      renderTo: 'warps-chart',
      type: 'spline'
    },
    title: player + ': Warps per Year',
    xAxis: { categories: year_list },
    yAxis: { title: {text: 'Warps'} },
    series: [{
      name: 'Warps',
      data: warps_list
    }],
  });

};

