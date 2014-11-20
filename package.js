Package.describe({
  name: 'ccorcos:swipe',
  summary: 'A package for creating apps that swipe between pages',
  version: '1.0.9',
  git: 'https://github.com/ccorcos/meteor-swipe.git'
});

Package.onUse(function(api) {
  api.versionsFrom('1.0');

  api.use(['templating', 'coffeescript'], 'client')

  api.addFiles(['swipe/swipe.html', 'swipe/swipe.coffee', 'swipe/swipe.css'], 'client');

  api.export('Swipe', ['client'])

});

// Package.onTest(function(api) {
//   api.use('tinytest');
//   api.use('ccorcos:swipe');
//   api.addFiles('ccorcos:swipe-tests.js');
// });
