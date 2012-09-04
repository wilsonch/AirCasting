function SessionsGraphCtrl($scope, map, graph, flash, heat, sensors, singleSession,
                           graphHighlight, $window) {
  $scope.graph = graph;
  $scope.$window = $window;
  $scope.expanded = false;
  $scope.heat = heat;
  $scope.sensors = sensors;
  $scope.singleSession = singleSession;

  $scope.graphWidth = function() {
    return $window.innerWidth - 608 + ($scope.expanded ? 1 : 0);
  };

  $scope.$watch("sensors.anySelectedId()", function(id){
    $scope.expanded = false;
  });

  $scope.$watch("singleSession.id()", function(id){
    $scope.expanded = false;
  });

  $scope.css = function() {
    return $scope.expanded ? "" : "collapsed";
  };
  $scope.$watch("expanded", function(expanded) {
    if(!expanded){
      graphHighlight.hide();
    }
  });
  $scope.toggle = function(){
    var sessionsSize = singleSession.noOfSelectedSessions();
    if(sessionsSize === 0) {
      flash.set("Please select one session to view the graph");
      return;
    } else if(sessionsSize > 1) {
      flash.set("You can have only one session selected to view the graph. Currently you have " + sessionsSize);
      return;
    } else if(!singleSession.get().loaded) {
      flash.set("You need to wait till session be loaded");
      return;
    }
    $scope.expanded = !$scope.expanded;
  };

  $scope.shouldRedraw = function() {
    return singleSession.isSingle() && !!sensors.anySelected() && !!singleSession.get().loaded;
  };

  $scope.$watch("shouldRedraw()", function(ready) {
    graphHighlight.hide();
    if(ready){
      graph.redraw();
    }
  }, true);

  $scope.$watch("heat.getValues()", function() {
    if($scope.shouldRedraw()){
      graph.redraw();
    }
  }, true);
}
SessionsGraphCtrl.$inject = ['$scope', 'map',  'graph', 'flash', 'heat', 'sensors',
  'singleSession', 'graphHighlight', '$window'];


