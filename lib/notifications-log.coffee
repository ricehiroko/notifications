{Emitter, CompositeDisposable, Disposable} = require 'atom'
NotificationsLogItem = require './notifications-log-item'

typeIcons =
  fatal: 'bug'
  error: 'flame'
  warning: 'alert'
  info: 'info'
  success: 'check'

module.exports = class NotificationsLog
  logItems: []

  constructor: (@duplicateTimeDelay) ->
    @emitter = new Emitter
    @disposables = new CompositeDisposable
    @render()
    atom.workspace.open(this, {
      activatePane: false
      activateItem: false
      searchAllPanes: true
    })

  render: ->
    @element = document.createElement('div')
    @element.classList.add('notifications-log')

    header = document.createElement('header')
    @element.appendChild(header)

    for type, icon of typeIcons
      button = document.createElement('button')
      button.classList.add('notification-type', 'btn', 'icon', "icon-#{icon}", 'show-type', type)
      button.dataset.type = type
      button.addEventListener 'click', (e) => @toggleType(e.target.dataset.type)
      @disposables.add atom.tooltips.add(button, {title: "Toggle #{type} notifications"})
      header.appendChild(button)

    @list = document.createElement('ul')
    @list.classList.add('notifications-log-items')
    @element.appendChild(@list)

    lastNotification = null
    for notification in atom.notifications.getNotifications()
      if lastNotification?
        # do not show duplicates unless some amount of time has passed
        timeSpan = notification.getTimestamp() - lastNotification.getTimestamp()
        unless timeSpan < @duplicateTimeDelay and notification.isEqual(lastNotification)
          @addNotification(notification)
      else
        @addNotification(notification)

      lastNotification = notification

    @disposables.add new Disposable => @element.remove()

  destroy: ->
    @disposables.dispose()
    @emitter.emit 'did-destroy'

  getElement: -> @element

  getURI: -> 'atom://notifications/log'

  getTitle: -> 'Log'

  getLongTitle: -> 'Notifications Log'

  getIconName: -> 'alert'

  getDefaultLocation: -> 'bottom'

  getAllowedLocations: -> ['left', 'right', 'bottom']

  toggle: -> atom.workspace.toggle(this)

  toggleType: (type, force) ->
    button = @element.querySelector(".notification-type.#{type}")
    hide = not button.classList.toggle('show-type', force)
    @list.classList.toggle("hide-#{type}", hide)

  addNotification: (notification) ->
    logItem = new NotificationsLogItem(notification)
    logItem.onClick => @emitter.emit('item-clicked', notification)
    @logItems.push logItem
    @list.insertBefore(logItem.getElement(), @list.firstChild)

    @disposables.add new Disposable -> logItem.destroy()

  onItemClick: (callback) ->
    @emitter.on 'item-clicked', callback

  onDidDestroy: (callback) ->
    @emitter.on 'did-destroy', callback
