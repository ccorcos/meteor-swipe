# Meteor Swipe

This package comes with all the bells and whistles for creating an app with swiping between pages. Checkout [this repo for some examples](https://github.com/ccorcos/meteor-swipe-examples).

## Getting Started

Add this package to your project:

```
meteor add ccorcos:swipe
```

Create some templates. And initialize a swiper with those template names.

`Swiper = new Swipe(['page1', 'page2', 'page3', 'page4', 'page5'])`

Insert the swiper somewhere and make sure to pass the swiper object.

```
<template name="main">
  <div class="wrapper">
    {{>swipe Swiper=Swiper}}
  </div>
</template>
```

Don't forget the helper.

```
Template.main.helpers
  Swiper: -> Swiper
```

Control the layout of the pages by reactively setting the left and right
pages.

```
Template.main.rendered = ->

  # initial page
  Swiper.setInitialPage('page1')

  # page control
  Tracker.autorun ->
    if Swiper.pageIs('page1')
      Swiper.leftRight(null, 'page2')

  Tracker.autorun ->
    if Swiper.pageIs('page2')
      Swiper.leftRight('page1', 'page3')

  Tracker.autorun ->
    if Swiper.pageIs('page3')
      Swiper.leftRight('page2', 'page4')


  Tracker.autorun ->
    if Swiper.pageIs('page4')
        Swiper.leftRight('page3', 'page5')

  Tracker.autorun ->
    if Swiper.pageIs('page5')
      Swiper.leftRight('page4', null)
```

`setInitialPage` sets the current page without any animation.

To prevent a swipe from starting on a certain element, simply add a `no-swipe`
class to that element.

If you want to be able to click or touch an element within the swiper, you have
to use the `click` function. This takes care of making sure that you
touch up inside the element you intent to click.

```
Swiper.click 'page1', '.pop-up', (e,t) ->
  alert 'hey!'
```

And if you want to control control swiping, you'll need to set the "swipe-control" class
```
Swiper.click 'page1', '.next', (e,t) ->
  Swiper.moveRight()
```

Lastly, if you want to vertically scroll a div, use the `scrollable` class.


## Known Issues
- Bugs out when the mouse drags off screen.
- Can be abused in Safari with touches somehow.
