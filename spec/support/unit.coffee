module.exports = (config) ->
  config.set
    basePath: '../../'
    frameworks: ['jasmine']
    files: [
      'spec/**/*_spec.coffee'
      'spec/lib/batman.js'
      'https://cdn.firebase.com/js/client/1.0.2/firebase.js'
      'batfire.coffee'
      'spec/support/spec_helper.coffee'
    ]
    reporters: ['dots']
    port: 9876
    colors: true
    logLevel: config.LOG_INFO
    autoWatch: true
    browsers: ['Chrome']
    captureTimeout: 60000
    singleRun: false
