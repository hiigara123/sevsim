class window.App
  constructor: ->
    @score = 0
    @stepNum = 0
    @chart = chartFactory 'chart-container'
    @moral = 100
    @pain = 0
    @curDate = new Date(2014, 2, 16)
    @stepSubscribers = []
    @view = new window.AppView
    @terpenium = 100

  subscribeStep: (fn) =>
    @stepSubscribers.push fn

  unsubscribeStep: (fn) =>
    @stepSubscribers = @stepSubscribers.filter (item) ->
      return item if item != fn

  fireStep: =>
    for subscriber in @stepSubscribers
      subscriber.call @stepNum

  start: ->
    @interval = setInterval @makeStep, 1000
    ActionManager.enableActions()
    @makeStep()

  stop: ->
    @suspend()

  suspend: ->
    clearInterval @interval
    ActionManager.disableActions()


  makeStep: =>
    @stepNum++
    @curDate = new Date(@curDate.getTime() + ONE_DAY)

    @fireStep()

    # 1. ActionManager.makeStep
    @makeActionStep()
    
    # 2. calculateScores
    @calculateStepScore()

    # 3. renderScores
    @view.render()

    # 4. updateChart
    @updateChart()

  makeActionStep: =>
    # ---- delta MORAL ----
    @deltaMoral = @calculateDeltaMoral()
    @moral += @deltaMoral

    @moral = 100 if @moral > 100
    @moral = 0 if @moral < 0

    # ---- delta PAIN ----
    @deltaPain = @calculateDeltaPain()

    @pain += @deltaPain

    @checkMaxPain()
    @updateTerpenium()

    @pain = 100 if @pain > 100
    @pain = 0 if @pain < 0

  calculateDeltaPain: =>
    dpain = ActionManager.deltas.pain.shift()
    return dpain if typeof dpain != 'undefined'
    if (@moral >= 100)
      return -2
    if (@moral >= 80)
      return -1
    Math.min(-(@moral - 40) / 100, -0.15)

  calculateDeltaMoral: =>
    deltaMoral = ActionManager.deltas.moral.shift()
    if typeof deltaMoral != 'undefined'
      return deltaMoral
    if @pain == 0
      return -1
    if @moral >= 80
      return -0.25
    -0.1


  updateTerpenium: ->
    @deltaTerpenium = @calculateStepTerpenium()
    @terpenium += @deltaTerpenium

    if @terpenium > 100
      @terpenium      = 100
      @deltaTerpenium = 0

    if @terpenium <= 0
      @terpenium      = 0
      @gameOver()

  gameOver: ->
    if @moral > 25
      alert "Твой севастополец не вытерпел унижений и умер, но не расстраивайся, ведь ты исполнил его мечту \u2014 он умер в России."
    else
      alert "Твой севастополец не вытерпел унижений, забандерложился и свалил в фашистскую Укропию, где не кормят говном с ложки."
    @stop()

  calculateStepTerpenium: ->
    if @pain == 100
      return -1.5
    if @pain >= 90
      return -0.7
    if @pain >= 80
      return -0.25

    if @moral == 100
      return +1.5
    if @moral >= 90
      return +0.5
    if @moral >= 80
      return +0.35
    if @moral == 0
      return -0.45
    0


  checkMaxPain: ->
    if @pain >= 100
      @maxPainLeft = 7
    else if @maxPainLeft > 0
      @maxPainLeft = @maxPainLeft - 1

    if @maxPainLeft > 0
      @pain = 100


  updateChart: ->
    @chart.series[0].addPoint [@curDate.getTime(), @moral], true, @stepNum > 15
    @chart.series[1].addPoint [@curDate.getTime(), @pain], true, @stepNum > 15

    minEx = new Date(@curDate.getTime() - (ONE_DAY * 10))
    maxEx = new Date(@curDate.getTime() + (ONE_DAY * 3))
    @chart.xAxis[0].setExtremes(minEx, maxEx)


  calculateStepScore: ->
    @calculateLevel()

    @stepScore = (@pain * ((@level+1) * 2)) ** 2
    # if @pain == 100
    #   tmpDelta = (@stepScore ** 2) / 10
    #   @stepScore += tmpDelta

    # @stepScore = @stepScore ** (@level + 1)
    # @stepScore = @stepScore * 

    # @stepScore = @stepScore * (2 ** @level)

    if @pain == 100
      @stepScore = @stepScore * 8

    # console.log "Step #{@stepScore}"

    @maxStepScore = ((@pain * 3) ** 4) ** (@level + 1)

    @score += @stepScore

  calculateLevel: ->
    @level = Math.round(
      Math.pow(
        Math.max(0, (@score - 10000) / 3),
        1/10
      )
    ) - 2
    @level = Math.max(@level, 0)

    ls = [
      0,             # не севастополец
      300000,        # подпиндосник
      30000000,      # аксенов
      300000000,     # чалый
      3000000000,    # меняйло
      300000000000,  # путин
      30000000000000 # говномидас
    ]
    ls = ls.reverse()
    for v, i in ls
      if @score >= v
        @level = ls.length - i - 1
        break
    console.log "Level #{i}"



window.ONE_DAY = 86400000


$ ->
  window.app = new App
  app.start()
