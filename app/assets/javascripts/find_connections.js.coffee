class window.FindConnections
  constructor: (@graph) ->
    @container = $("#graph-canvas");
    @width = @height = 500

    @initialize()

  initialize: =>
    @force = d3.layout.force()
      .charge(-120)
      .linkDistance(30)
      .size([@width, @height])

    @svg = d3.select('#graph-canvas').append('svg')
      .attr("width", @width)
      .attr("height", @height)

    @reloadFromData()

  reloadFromData: =>
    @node = @svg.selectAll(".node")
      .data(@graph.nodes, (d) -> d.id)

    @node.enter().append("circle")
      .attr("class", (d) -> "node " + FindConnections.processClass(d.type) + "-color")
      .attr("r", 15)
      .append("title")
      .text((d) -> d.title)
    @node.call(@force.drag)
    @node.exit().remove()

    @link = @svg.selectAll(".link")
      .data(@graph.edges, (d) -> d.source + "-" + d.target)
    @link.enter().insert("line", ".node")
      .attr("class", "link")
      .style("stroke-width", 2)
    @link.exit().remove()

    @force.on("tick", =>
      @link.attr("x1", (d) -> d.source.x)
        .attr("y1", (d) -> d.source.y)
        .attr("x2", (d) -> d.target.x)
        .attr("y2", (d) -> d.target.y)

      @node.attr("cx", (d) -> d.x)
        .attr("cy", (d) -> d.y)
    )

    @force.nodes(@graph.nodes)
      .links(@graph.edges)
      .linkDistance(60)
      .start()

  selectItem: (item) =>
    $.ajax({
      url: document.location.href,
      dataType: 'json',
      type: 'get',
      data: {target: item},
      success: (resp) =>
        @graph = resp.graph
        @reloadFromData()

      error: (resp) =>
        console.log('Error', resp)
    })
  @processClass: (klass) =>
    comp = klass.split('::')
    comp[comp.length - 1].toLowerCase().replace('type', '').replace('base', '')
