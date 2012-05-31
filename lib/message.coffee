Segment = require('./Segment')
HeadSegment = require('./HeadSegment')

queryparser = require('../definitions/query')

class Message
  constructor: (raw) ->
    [msh, segments...] = raw
    @errors = []
    @segments = []

    # all messages have a head segment to start with; it's handled a bit differently
    @segments.push(new HeadSegment(msh))
    _.each(segments, (segment) ->
      @segments.push(new Segment(segment))
    , @)
    @validate()
    return
  getSegment: (name) ->
    _.find(@segments, (segment) ->
      segment.name is name
    )
  validate: ->
    @errors.push('Missing MSH segment') unless msh?.name is 'MSH'
    @valid = @errors.length is 0
  query: (query) ->
    try
      { component, field, segment, toDate } = queryparser.parse(query)

      fieldEl = @getSegment(segment)?.getField(field)
      if _.isNull(component)
        if _.isUndefined(fieldEl)
          val = null
        else
          val = fieldEl?.val()
      else
        componentEl = fieldEl?.getComponent(component)
        if _.isUndefined(componentEl)
          val = null
        else
          val = componentEl.val()
      if toDate
        match = val.match(/(\d{4})(\d{2})(\d{2})(\d{2})?(\d{2})?(\d{2})?/)
        if match
          [datestring, year, month, day, hours, minutes, seconds] = match
          hours ?= 0
          minutes ?= 0
          seconds ?= 0
          date = new Date(year, Number(month) - 1, day, hours, minutes, seconds, 0)
        else
          null
      else
        val
    catch e
      throw new Error("Bad selector '#{query}'")
  translate: (map) ->
    _.reduce(map, (memo, val, key) =>
      memo[key] = @query(val)
      memo
    , {})

module.exports = Message
