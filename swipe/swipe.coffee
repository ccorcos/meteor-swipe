

class Swipe
  constructor: (@templateNames, arrowKeys=true) ->
    @state = new Package['reactive-dict'].ReactiveDict()
    @state.set 'page', null
    @left =  null
    @right =  null
    @t = null # template
    @lastPage = null

    self = @
    # react to window resizing!
    $(window).resize ->
      self.t?.width = $(self.t?.find('.pages')).width()
      self.resize()

    if arrowKeys
      document.onkeydown = (e) ->
        if not e then e = window.event
        code = e.keyCode
        if code is 37
          event.preventDefault()
          # let moveLeft handle the animations. This fixes the 3 page example.
          $(self.t?.findAll('.animate')).removeClass('animate')
          self.moveLeft()
        else if code is 39
          event.preventDefault()
          # let moveLeft handle the animations. This fixes the 3 page example.
          $(self.t?.findAll('.animate')).removeClass('animate')
          self.moveRight()
        # else if code is 38 # up
        # else if code is 40 # down


  isReady: ->
    # if calling setPage before swiper is bound to a template, we get an error.
    # so this function is just a semantic wrapper for checking if the template
    # exists yet.
    return @t?

  setTemplate: (t) ->
    @t = t
    # initially hide
    # for name in @templateNames
    #   $(@t.find('.page.'+name)).css 'display', 'none'

  getPage: () ->
    @state.get 'page'

  setPageHard: (name) ->
    for n in _.difference(@templateNames, [n])
      $(@t.find('.page.'+n)).css 'display', 'none'
    @setPage(name)
    $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
      'translate3d(0px,0,0)'

  setPage: (name) ->
    @lastPage = @getPage()
    @state.set 'page', name
    # set position in the middle regardless of animation
    # $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
    #   'translate3d(0px,0,0)'

  pageIs: (name) ->
    @state.equals 'page', name

  getLeft: () ->
    @left

  setLeft: (name) ->
    @left =  name
    # set position in the left regardless of animation
    $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
      'translate3d(-'+@t.width+'px,0,0)'

  leftIs: (name) ->
    @state.equals 'left', name

  getRight: () ->
    @right

  setRight: (name) ->
    @right =  name
    # set position in the middle regardless of animation
    $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
      'translate3d('+@t.width+'px,0,0)'

  rightIs: (name) ->
    @state.equals 'right', name


  drag: (posX) ->
    width = @t.width

    # Cant scroll in the direction where there is no page!
    if @getLeft()
      # positive posx reveals left
      posX = Math.min(width, posX)
    else
      posX = Math.min(0, posX)

    if @getRight()
      # negative posx reveals right
      posX = Math.max(-width, posX)
    else
      posX = Math.max(0, posX)

    # update the page positions
    if @getLeft()
      $(@t.find('.page.'+@getLeft())).css 'transform',
        'translate3d(-' + (width - posX) + 'px,0,0)'
    if @getRight()
      $(@t.find('.page.'+@getRight())).css 'transform',
        'translate3d(' + (width + posX) + 'px,0,0)'
    $(@t.find('.page.'+@getPage())).css 'transform',
      'translate3d(' + posX + 'px,0,0)'

  animateBack: () ->
    # Animate all pages back into place
    $(@t.findAll('.page')).addClass('animate')

    if @getLeft()
      $(@t.find('.page.'+@getLeft())).css 'transform',
        'translate3d(-' + @t.width + 'px,0,0)'
    if @getRight()
      $(@t.find('.page.'+@getRight())).css 'transform',
        'translate3d(' + @t.width + 'px,0,0)'
    $(@t.find('.page.'+@getPage())).css 'transform',
      'translate3d(0px,0,0)'


  moveLeft: () ->
    if @getLeft()
      # only animate the center and the left towards the right
      $(@t.find('.page.'+@getPage())).addClass('animate').css 'transform',
        'translate3d('+@t.width+'px,0,0)'
      $(@t.find('.page.'+@getLeft())).addClass('animate').css 'transform',
        'translate3d(0px,0,0)'
      @setPage(@getLeft())

  moveRight: () ->
    if @getRight()
      # only animate the center and the left towards the right
      $(@t.find('.page.'+@getPage())).addClass('animate').css 'transform',
        'translate3d(-'+@t.width+'px,0,0)'
      $(@t.find('.page.'+@getRight())).addClass('animate').css 'transform',
        'translate3d(0px,0,0)'
      @setPage(@getRight())


  leftRight: (left, right) ->
    oldLeft = @getLeft()
    oldRight = @getRight()


    center = @getPage()
    @setLeft(left)
    @setRight(right)

    # dont hide the old center!
    for name in _.difference(@templateNames, [left, center, right, @lastPage])
      $(@t.find('.page.'+name)).css 'display', 'none'


  resize: ->
    $(@t.findAll('.animate')).removeClass('animate')
    @setLeft(@getLeft())
    @setRight(@getRight())

  # These are effectively the same:

  # swipeControl Swiper, 'page1', '.next', (e,t) ->
  #   Swiper.moveRight()

  # Template.page1.events
  #   'mouseup .next': (e,t) ->
  #     console.log e
  #     Swiper.moveRight()
  #
  #   'touchend .next': (e,t) ->
  #     if e.currentTarget is Swiper.element
  #       Swiper.moveRight()

  shouldControl: ->
    speedX = 10*@t.velX
    flickX = @t.changeX + speedX
    return Math.abs(flickX) <= 30 or Math.abs(@t.changeX) <= 10

  swipeControl: (template, selector, handler) ->
    Swiper = @
    mouseup = 'mouseup ' + selector
    touchend = 'touchend ' + selector
    eventMap = {}

    eventMap[mouseup] = (e,t) ->
      if Swiper.shouldControl()
        handler.bind(@)(e,t)
    eventMap[touchend] = (e,t) ->
      if e.currentTarget is Swiper.element and Swiper.shouldControl()
        e.stopPropagation()
        handler.bind(@)(e,t)

    t = Template[template]
    if t
      t.events eventMap
    else
      console.log "WARNING: Template '" + template + "' not found."


Template.swipe.helpers
  pages: -> _.map @Swiper?.templateNames, (name) -> {name: name}


Template.swipe.rendered = ->
  # check that templateNames is passed
  if not @data.Swiper
    console.log("ERROR: must pass a Swipe object.")
  else
    @Swiper = @data.Swiper
    @Swiper.setTemplate(@)

  @width = $(@find('.pages')).width()

  # keep track of scrolling
  @mouseDown = false
  @startX = 0
  @mouseX = 0
  @posX = 0
  @startY = 0
  @mouseY = 0
  @posY = 0

Template.swipe.events
  'mousedown .pages': (e,t) ->
    noSwipeCSS = $(e.target).hasClass('no-swipe') or $(e.target).parentsUntil('body', '.no-swipe').length

    unless noSwipeCSS
      # remove stop all animations in this swiper
      $(t.findAll('.animate')).removeClass('animate')
      clickX = e.pageX
      t.startX = clickX # beginning of the swipe
      t.mouseX = clickX # current position of the swipe
      t.mouseDown = true # swipe has begun
      t.toppedOutScroll = false


  'touchstart .pages': (e,t) ->
    # stops mousedown and up but ruins scroll
    # e.stopPropagation()
    # e.preventDefault()

    t.toppedOutScroll = false

    noSwipeCSS = $(e.target).hasClass('no-swipe') or $(e.target).parentsUntil('body', '.no-swipe').length
    scrollableCSS = $(e.target).hasClass('scrollable') or $(e.target).parentsUntil('body', '.scrollable').length
    if scrollableCSS
      t.scrollable = true
      t.mightBeScrolling = true
      t.scrolling = false
    else
      t.scrollable = false
      t.mightBeScrolling = false
      t.scrolling = false

    unless noSwipeCSS

      # keep track of what element the pointer is over for touchend
      x = e.originalEvent.touches[0].pageX - window.pageXOffset
      y = e.originalEvent.touches[0].pageY - window.pageYOffset
      target = document.elementFromPoint(x, y)
      t.Swiper.element = target

      # remove stop all animations in this swiper
      $(t.findAll('.animate')).removeClass('animate')
      # keey track of Y for calculating scroll
      clickX = e.originalEvent.touches[0].pageX
      clickY = e.originalEvent.touches[0].pageY
      t.startX = clickX # beginning of the swipe
      t.mouseX = clickX # current position of the swipe
      t.startY = clickY # beginning of the swipe
      t.mouseY = clickY # current position of the swipe
      t.mouseDown = true # swipe has begun

  'mousemove .pages': (e,t) ->

    if t.mouseDown
      newMouseX = e.pageX
      oldMouseX = t.mouseX
      t.velX = newMouseX - oldMouseX
      t.changeX = newMouseX - t.startX
      posX = t.changeX + t.posX
      t.mouseX = newMouseX
      t.Swiper.drag(posX)

  'touchmove .pages': (e,t) ->

    # if you mightBeScrolling
    #   compare with dx and dy to set if scrolling
    #   if not scrolling
    #     prevent default and swipe
    # else
    #   if not scrolling
    #     unless noSwipe
    #     prevent default and swipe

    # if t.mouseDown

    noSwipeCSS =  $(e.target).hasClass('no-swipe') or $(e.target).parentsUntil('body', '.no-swipe').length

    # console.log(t.scrollable, t.mightBeScrolling, t.scrolling)


    if t.mightBeScrolling

      # keep track of what element the pointer is over for touchend
      x = e.originalEvent.touches[0].pageX - window.pageXOffset
      y = e.originalEvent.touches[0].pageY - window.pageYOffset
      target = document.elementFromPoint(x, y)
      t.Swiper.element = target

      newMouseX = e.originalEvent.touches[0].pageX
      oldMouseX = t.mouseX
      t.velX = newMouseX - oldMouseX
      t.changeX = newMouseX - t.startX
      posX = t.changeX + t.posX
      t.mouseX = newMouseX

      newMouseY = e.originalEvent.touches[0].pageY
      oldMouseY = t.mouseY
      t.velY = newMouseY - oldMouseY
      t.changeY = newMouseY - t.startY
      posY = t.changeY + t.posY
      t.mouseY = newMouseY

      speedX = 10*t.velX
      flickX = t.changeX + speedX

      speedY = 10*t.velY
      flickY = t.changeY + speedY

      scrollElement = null
      if $(target).hasClass('scrollable')
        scrollElement = $(target)
      else
        scrollElement = $(target).parentsUntil('body', '.scrollable')[0]

      positionYTop = $(scrollElement).scrollTop()
      isScrolledToTop = if positionYTop is 0 then true else false

      innerHeight = $(scrollElement).innerHeight()
      contentHeight = scrollElement.scrollHeight

      isScrolledToBottom = if positionYTop + innerHeight >= contentHeight then true else false

      # console.log scrollElement, positionYTop, isScrolledToTop, innerHeight, contentHeight, isScrolledToBottom

      if Math.abs(flickY*1.66) > Math.abs(flickX)
        # scrolling
        t.mightBeScrolling = false
        t.scrolling = true

        # catch scrolling if its at the bounds
        if (flickY > 0 and isScrolledToTop) or (flickY < 0 and isScrolledToBottom)
          # just swipe
          t.mightBeScrolling = false
          t.scrolling = false
          t.toppedOutScroll = true
          e.preventDefault()
          # t.Swiper.drag(posX)
          return false
        else
          return true
      else
          if noSwipeCSS
            return true

          # swipe
          t.mightBeScrolling = false
          t.scrolling = false
          e.preventDefault()
          unless noSwipeCSS
            t.Swiper.drag(posX)
          return false
    else
      # scrolling or not
      if t.scrolling
        console.log "scrolling"
        return true
      else
        e.preventDefault()
        unless noSwipeCSS
          if t.toppedOutScroll
            return false

          # keep track of what element the pointer is over for touchend
          x = e.originalEvent.touches[0].pageX - window.pageXOffset
          y = e.originalEvent.touches[0].pageY - window.pageYOffset
          target = document.elementFromPoint(x, y)
          t.Swiper.element = target

          newMouseX = e.originalEvent.touches[0].pageX
          oldMouseX = t.mouseX
          t.velX = newMouseX - oldMouseX
          t.changeX = newMouseX - t.startX
          posX = t.changeX + t.posX
          t.mouseX = newMouseX

          newMouseY = e.originalEvent.touches[0].pageY
          oldMouseY = t.mouseY
          t.velY = newMouseY - oldMouseY
          t.changeY = newMouseY - t.startY
          posY = t.changeY + t.posY
          t.mouseY = newMouseY

          t.Swiper.drag(posX)
          return false



  'mouseup .pages': (e,t) ->

    if t.mouseDown
      posX = t.changeX + t.posX
      momentum = Math.abs(10*t.velX)
      momentum = Math.min(momentum, t.width/2)
      momentum = momentum*sign(t.velX)
      distance = posX + momentum
      if ($(e.target).hasClass('swipe-control') or $(e.target).parentsUntil('body', '.swipe-control').length) and e.target is t.Swiper.element and t.Swiper.shouldControl()
        t.velX = 0
        t.startX = 0
        t.mouseX = 0
        t.changeX = 0
        t.mouseDown = false
        return

      index = Math.round(distance / t.width)
      if index is -1
        t.Swiper.moveRight()
      else if index is 1
        t.Swiper.moveLeft()
      else
        t.Swiper.animateBack()

      t.velX = 0
      t.startX = 0
      t.mouseX = 0
      t.changeX = 0
      t.mouseDown = false

  'mouseout .pages': (e,t) ->
    if t.mouseDown
      parentToChild = e.fromElement is e.toElement?.parentNode
      childToParent = _.contains(e.toElement?.childNodes, e.fromElement)
      if not (parentToChild or childToParent)
        posX = t.changeX + t.posX
        momentum = Math.abs(10*t.velX)
        momentum = Math.min(momentum, t.width/2)
        momentum = momentum*sign(t.velX)
        index = Math.round((posX + momentum) / t.width)
        if index is -1
          t.Swiper.moveRight()
        else if index is 1
          t.Swiper.moveLeft()
        else
          t.Swiper.animateBack()

        t.velX = 0
        t.startX = 0
        t.mouseX = 0
        t.changeX = 0
        t.mouseDown = false

    scrollOffPage = e.toElement is document.querySelector("html")
    if scrollOffPage
      # Not handling this well
      t.velX = 0
      t.startX = 0
      t.mouseX = 0
      t.changeX = 0
      t.mouseDown = false

  # mouseout and touchcancel
  'touchend .pages': (e,t) ->
    if t.mouseDown
      posX = t.changeX + t.posX
      momentum = Math.abs(10*t.velX)
      momentum = Math.min(momentum, t.width/2)
      momentum = momentum*sign(t.velX)
      distance = posX + momentum
      # console.log ($(e.target).hasClass('swipe-control') or $(e.target).parentsUntil('body', '.swipe-control').length), e.target, t.Swiper.element, t.Swiper.shouldControl()
      if ($(e.target).hasClass('swipe-control') or $(e.target).parentsUntil('body', '.swipe-control').length) and e.target is t.Swiper.element and t.Swiper.shouldControl()
        t.velX = 0
        t.startX = 0
        t.mouseX = 0
        t.changeX = 0
        t.mouseDown = false
        return true

      index = Math.round(distance / t.width)
      if index is -1
        t.Swiper.moveRight()
      else if index is 1
        t.Swiper.moveLeft()
      else
        t.Swiper.animateBack()

      t.velX = 0
      t.startX = 0
      t.mouseX = 0
      t.changeX = 0
      t.mouseDown = false





sign = (x) ->
  if x >= 0 then return 1 else return -1

bound = (min, max, n) ->
  Math.min(Math.max(min, n), max)

wrap = (min, max, n) ->
  if n < min
    return max - (min - 1) - 1
  else if n > max
    return min + (n - max) - 1
  else
    return n


delay = (ms, func) -> setTimeout func, ms
