module.exports = (config) ->
  config.set
    basePath: '../'
    frameworks: ['jasmine'] # that's my weapon of choice, anyways.
    files: [
      'spec/batman.firebase/**/*.coffee' # load your tests
      'spec/lib/batman.js'
      'src/batman.firebase.coffee'
      'spec/spec_helper.coffee'
    ]
    reporters: ['dots']
    port: 9876
    colors: true
    logLevel: config.LOG_INFO
    autoWatch: true
    browsers: ['Chrome']
    captureTimeout: 60000
    singleRun: false
