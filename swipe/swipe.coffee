
eventPrint = (msg) ->
  if false
    console.log msg

debugPrint = (msg) ->
  if false
    console.log msg

class Swipe
  constructor: (@templates, arrowKeys=true) ->
    # @templates is a list of template name strings that will be used by
    # the Swiper

    # Create a reactive dictionary so the current page can be a reactive variable
    @state = new Package['reactive-dict'].ReactiveDict()
    @state.set 'page', null
    # Handle the left and right pages manually. Otherwise every transition will trigger
    # multiple reactive autoruns
    @left =  null
    @right =  null
    # keep track of the previous page so we make make sure not to hide it so the
    # animations finish when the page drops.
    @previousPage = null
    # Keep track of the template this object is bound to so we can t.find specifically
    # within the template and manage template variables.
    # The template manages all the touch events and drag-swiping. The swiper manages
    # the pages.
    @t = null # template

    self = @
    # When the window resizes, reposition the left and right
    $(window).resize ->
      # set the width of the page so the template knows where to position
      # the left and right pages
      self.t?.width = $(self.t?.find('.pages')).width()
      # do not animate the window resizing
      $(self.t.findAll('.animate')).removeClass('animate')
      # re-position the left and right pages.
      self.setLeft self.left
      self.setRight self.right

    # If we want to allow arrow keys to swipe, we need to register the arrow key
    # events
    if arrowKeys
      document.onkeydown = (e) ->
        if not e then e = window.event
        code = e.keyCode
        if code is 37
          event.preventDefault()
          # clear animations will immediately finish the previous animation
          # and moveLeft will execute the next animation
          self.clearAnimate()
          self.moveLeft()
        else if code is 39
          event.preventDefault()
          # clear animations will immediately finish the previous animation
          # and moveRight will execute the next animation
          self.clearAnimate()
          self.moveRight()

  clearAnimate: ->
    $(@t?.findAll('.animate')).removeClass('animate')

  animateAll: ->
    $(@t.findAll('.page')).addClass('animate')

  animateRight: (name) ->
    $(@t.find('.page.'+name)).addClass('animate').css 'transform',
      'translate3d('+@t.width+'px,0,0)'

  animateLeft: (name) ->
    $(@t.find('.page.'+name)).addClass('animate').css 'transform',
      'translate3d(-'+@t.width+'px,0,0)'

  animateCenter: (name) ->
    $(@t.find('.page.'+name)).addClass('animate').css 'transform',
      'translate3d(0px,0,0)'

  # set position regardless of animation
  displayRight: (name) ->
    $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
      'translate3d('+@t.width+'px,0,0)'

  displayLeft: (name) ->
    $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
      'translate3d(-'+@t.width+'px,0,0)'

  displayCenter: (name) ->
    $(@t.find('.page.'+name)).css('display', 'block').css 'transform',
      'translate3d(0px,0,0)'

  transitionRight: (name) ->
    @hidePage @previousPage
    @setRight name
    @moveRight()

  transitionLeft: (name) ->
    @hidePage @previousPage
    @setLeft name
    @moveLeft()

  moveLeft: ->
    if @left
      # only animate the center and the left towards the right
      @animateRight @getPage()
      @animateCenter @left
      @setPage @left

  moveRight: ->
    if @right
      # only animate the center and the left towards the right
      @animateLeft @getPage()
      @animateCenter @right
      @setPage @right

  setPage: (name) ->
    # this method will simply trigger any functions that autorun reactively on
    # the current page. This assumes whatever function is calling it will
    # take cre of any animations or transitions.
    @previousPage = @getPage()
    @state.set 'page', name

  hidePage: (name) ->
    $(@t.find('.page.'+name)).css 'display', 'none'

  setInitialPage: (name) ->
    # hide everything when placing the initial page
    # the left and right should be unhidden later.
    for n in @templates
      if n isnt name then @hidePage n
    @setPage name
    # place this page in the center
    @displayCenter name

  setTemplate: (t) ->
    @t = t

  getPage: () ->
    @state.get 'page'

  pageIs: (name) ->
    # used as a reactive binding in an autorun to manage left and right pages
    @state.equals 'page', name

  setLeft: (name) ->
    @left =  name
    @displayLeft name

  setRight: (name) ->
    @right =  name
    @displayRight name

  drag: (posX) ->
    width = @t.width

    # Cant scroll in the direction where there is no page!
    if @left
      # positive posx reveals left
      posX = Math.min(width, posX)
    else
      posX = Math.min(0, posX)

    if @right
      # negative posx reveals right
      posX = Math.max(-width, posX)
    else
      posX = Math.max(0, posX)

    # update the page positions
    if @left
      $(@t.find('.page.'+@left)).css 'transform',
        'translate3d(-' + (width - posX) + 'px,0,0)'
    if @right
      $(@t.find('.page.'+@right)).css 'transform',
        'translate3d(' + (width + posX) + 'px,0,0)'

    $(@t.find('.page.'+@getPage())).css 'transform',
      'translate3d(' + posX + 'px,0,0)'

  animateBack: () ->
    # Animate all pages back into place
    @animateAll()

    if @left
      $(@t.find('.page.'+@left)).css 'transform',
        'translate3d(-' + @t.width + 'px,0,0)'

    if @right
      $(@t.find('.page.'+@right)).css 'transform',
        'translate3d(' + @t.width + 'px,0,0)'

    $(@t.find('.page.'+@getPage())).css 'transform',
      'translate3d(0px,0,0)'

  leftRight: (left, right) ->
    debugPrint 'leftRight'
    center = @getPage()
    @setLeft left
    @setRight right

    # dont hide the old center to give it time to animate offscreen just in case
    # it is removed.
    dontHide = [left, center, right, @previousPage]
    hideThese = _.difference(@templates, dontHide)

    for name in hideThese
      @hidePage name




  shouldControl: ->
    # don't register a click if the page is scrolled or being flicked.
    speedX = 10*@t.velX
    flickX = @t.changeX + speedX
    speedY = 10*@t.velY
    flickY = @t.changeY + speedY
    Xok = Math.abs(flickX) <= 30 or Math.abs(@t.changeX) <= 10
    Yok = Math.abs(flickY) <= 30 or Math.abs(@t.changeY) <= 10
    return Xok and Yok


  # These are effectively the same:

  # click Swiper, 'page1', '.next', (e,t) ->
  #   Swiper.moveRight()

  # Template.page1.events
  #   'mouseup .next': (e,t) ->
  #     console.log e
  #     Swiper.moveRight()
  #
  #   'touchend .next': (e,t) ->
  #     if e.currentTarget is Swiper.element
  #       Swiper.moveRight()

  click: (template, selector, handler) ->
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




# register the page names to dynamically render each page
Template.swipe.helpers
  pageNames: -> _.map @Swiper?.templates, (name) -> {name: name}


Template.swipe.rendered = ->
  # check that templates is passed
  if not @data.Swiper
    console.log("ERROR: must pass a Swipe object.")
  else
    # Bind the Swiper to this template and the template to the swiper
    @Swiper = @data.Swiper
    @Swiper.setTemplate(@)

  # keep track of the width so we know where to place pages to the left
  # and the right
  @width = $(@find('.pages')).width()

  # keep track of scrolling
  @mouseDown = false
  @touchDown = false
  @startX = 0
  @mouseX = 0
  @posX = 0
  @startY = 0
  @mouseY = 0
  @posY = 0

  # We need to keep track of whether the user is scrolling or swiping.
  @scrollableCSS = false
  @mightBeScrolling = false
  @scrolling = false
  @willOverscroll = false

  # prevent overscroll when necessary. This happens when the user drags down
  # when the page is at the top, or vice versa at the bottom


targetInClass = (name, target) ->
  $(target).hasClass(name) or $(target).parentsUntil('body', '.' + name).length

Template.swipe.events
  'mousedown .pages': (e,t) ->
    # if we're the user has already touched down, we want to ignore mouse events
    if t.touchDown
      return

    eventPrint "mousedown"
    noSwipeCSS = targetInClass 'no-swipe', e.target

    unless noSwipeCSS
      t.willOverscroll = false
      # remove stop all animations in this swiper
      t.Swiper.clearAnimate()
      clickX = e.pageX
      clickY = e.pageY

      t.startX = clickX # beginning of the swipe
      t.mouseX = clickX # current position of the swipe
      t.startY = clickY # beginning of the swipe
      t.mouseY = clickY # current position of the swipe
      t.mouseDown = true # click swipe has begun
      t.touchDown = false

  'touchstart .pages': (e,t) ->
    eventPrint "touchstart"
    t.willOverscroll = false

    noSwipeCSS = targetInClass 'no-swipe', e.target
    scrollableCSS = targetInClass 'scrollable', e.target

    # Check to see if the user touched inside of a scrollable div. If so,
    # then the user might be scrolling depending on whether he moves his finger
    # to the side to swipe or up and down to scroll. Once we have determined the
    # direction of the gesture, we can be certain of whether the user is scrolling
    # or not.
    if scrollableCSS
      t.scrollableCSS = true
      t.mightBeScrolling = true
      t.scrolling = false
    else
      t.scrollableCSS = false
      t.mightBeScrolling = false
      t.scrolling = false

    unless noSwipeCSS
      # keep track of what element the pointer is over for touchend
      x = e.originalEvent.touches[0].pageX - window.pageXOffset
      y = e.originalEvent.touches[0].pageY - window.pageYOffset
      target = document.elementFromPoint(x, y)
      t.Swiper.element = target

      # remove stop all animations in this swiper
      t.Swiper.clearAnimate()
      # key track of Y for calculating scroll
      clickX = e.originalEvent.touches[0].pageX
      clickY = e.originalEvent.touches[0].pageY
      t.startX = clickX # beginning of the swipe
      t.mouseX = clickX # current position of the swipe
      t.startY = clickY # beginning of the swipe
      t.mouseY = clickY # current position of the swipe
      # we must distinguish between mouse and touch because sometimes
      # touch will induce a click; touchend => mouseup
      t.mouseDown = false
      t.touchDown = true

  'mousemove .pages': (e,t) ->
    # if the mouse is pressed, we need to keep track of the swipe.
    # note that you cannot scroll by clicking the mouse!
    if t.mouseDown
      eventPrint "mousemove"
      newMouseX = e.pageX
      oldMouseX = t.mouseX
      t.velX = newMouseX - oldMouseX
      t.changeX = newMouseX - t.startX
      posX = t.changeX + t.posX
      t.mouseX = newMouseX

      newMouseY = e.pageY
      oldMouseY = t.mouseY
      t.velY = newMouseY - oldMouseY
      t.changeY = newMouseY - t.startY
      posY = t.changeY + t.posY
      t.mouseY = newMouseY

      t.Swiper.drag(posX)

  'touchmove .pages': (e,t) ->
    eventPrint "touchmove"

    # if you mightBeScrolling
    #   compare with dx and dy to set if scrolling
    #   if not scrolling
    #     prevent default and swipe
    # else
    #   if not scrolling
    #     unless noSwipe
    #     prevent default and swipe

    noSwipeCSS = targetInClass 'no-swipe', e.target

    # If we're not sure if the user is scrolling or not, then we need to check to
    # see if the first motion is left-right, or up-down.
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

      positionYTop = scrollElement.scrollTop
      isScrolledToTop = if positionYTop is 0 then true else false

      innerHeight = scrollElement.innerHeight
      contentHeight = scrollElement.scrollHeight

      isScrolledToBottom = if positionYTop + innerHeight >= contentHeight then true else false

      # compute the relative angles of up-down or left-right
      if Math.abs(flickY*1.66) > Math.abs(flickX)
        # we've determined that the user is definitely scrolling
        # so we don't want to compute this all over again. on the next
        # touchmove, just compute the scroll position.
        t.mightBeScrolling = false
        t.scrolling = true

        # catch scrolling if the user is scrolling beyond the bounds and
        # prevent the default safari functionality that drags the webpage, yuck.
        if (flickY > 0 and isScrolledToTop) or (flickY < 0 and isScrolledToBottom)
          t.mightBeScrolling = false
          t.scrolling = false
          t.willOverscroll = true
          e.preventDefault()
          return false
        else
          # continue with default scroll functionality.
          return true
      else
        # if the user is swiping, not scrolling, we can set the appropriate values
        t.mightBeScrolling = false
        t.scrolling = false
        # prevent the default scrolling functionality
        e.preventDefault()
        # DELETE COMMENT
        # if noSwipeCSS
        #   return true
        unless noSwipeCSS
          t.Swiper.drag(posX)
        return false
    else if t.scrolling
      # if we know the user is scrolling, we can just let the default
      # functionality handle it.
      return true
    else
      # if the user is swiping, then we need to prevent the default functionality
      # of scrolling.
      e.preventDefault()
      unless noSwipeCSS
        if t.willOverscroll
          # if the user tried to overscroll, prevent the entire gesture.
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

        # keep track of y, so we know if the `shouldControl` and we can measure both
        # x and y directions.
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
      eventPrint "mouseup"
      posX = t.changeX + t.posX
      momentum = Math.abs(10*t.velX)
      momentum = Math.min(momentum, t.width/2)
      momentum = momentum*sign(t.velX)
      distance = posX + momentum
      swipeControlCSS = targetInClass 'swipe-control', e.target
      # run the swiping event
      if swipeControlCSS and (e.target is t.Swiper.element) and t.Swiper.shouldControl()
        t.velX = 0
        t.startX = 0
        t.mouseX = 0
        t.changeX = 0
        t.velY = 0
        t.startY = 0
        t.mouseY = 0
        t.changeY = 0
        t.mouseDown = false
        return

      # otherwise, snap the page where it should go
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
      t.velY = 0
      t.startY = 0
      t.mouseY = 0
      t.changeY = 0
      t.mouseDown = false

  # 'mouseout .pages': (e,t) ->
  #   # this is tricky. mouseout of the entire webpage will fuck up everything.
  #   # I'm not sure how to deal with this.
  #
  #   # if t.mouseDown
  #   #   parentToChild = e.fromElement is e.toElement?.parentNode
  #   #   childToParent = _.contains(e.toElement?.childNodes, e.fromElement)
  #   #   if not (parentToChild or childToParent)
  #   #     posX = t.changeX + t.posX
  #   #     momentum = Math.abs(10*t.velX)
  #   #     momentum = Math.min(momentum, t.width/2)
  #   #     momentum = momentum*sign(t.velX)
  #   #     index = Math.round((posX + momentum) / t.width)
  #   #     if index is -1
  #   #       t.Swiper.moveRight()
  #   #     else if index is 1
  #   #       t.Swiper.moveLeft()
  #   #     else
  #   #       t.Swiper.animateBack()
  #   #
  #   #     t.velX = 0
  #   #     t.startX = 0
  #   #     t.mouseX = 0
  #   #     t.changeX = 0
  #   #     t.mouseDown = false
  #
  #   # scrollOffPage = e.toElement is document.querySelector("html")
  #   # if scrollOffPage
  #   #   # Not handling this well
  #   #   t.velX = 0
  #   #   t.startX = 0
  #   #   t.mouseX = 0
  #   #   t.changeX = 0
  #   #   t.mouseDown = false

  'touchend .pages': (e,t) ->
    if t.touchDown
      eventPrint "touchend"

      posX = t.changeX + t.posX
      momentum = Math.abs(10*t.velX)
      momentum = Math.min(momentum, t.width/2)
      momentum = momentum*sign(t.velX)
      distance = posX + momentum

      swipeControlCSS = targetInClass 'swipe-control', e.target
      # run the swiping event
      if swipeControlCSS and (e.target is t.Swiper.element) and t.Swiper.shouldControl()
        t.velX = 0
        t.startX = 0
        t.mouseX = 0
        t.changeX = 0
        t.velY = 0
        t.startY = 0
        t.mouseY = 0
        t.changeY = 0
        t.touchDown = false
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
      t.velY = 0
      t.startY = 0
      t.mouseY = 0
      t.changeY = 0
      t.touchDown = false
    return true


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
