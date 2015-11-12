{CompositeDisposable} = require 'atom'

module.exports = AtomPrinter =
  atomPrinterView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'printer:print': => @print()

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  print: ->
    iframe = document.createElement('iframe')

    iframe.style.visibility = 'hidden'
    iframe.style.position = 'fixed'
    iframe.style.right = 0
    iframe.style.bottom = 0

    document.body.appendChild(iframe)

    content = iframe.contentWindow
    content.document.body.className = document.body.className
    @addThemeStyles(content.document)

    container = content.document.createElement("pre")
    container.id = "lines"

    @addEditorContent(container)

    content.document.body.appendChild(container)
    content.print()
    document.body.removeChild(iframe)

  addEditorContent: (container) ->
    editor = atom.workspace.getActiveTextEditor()
    text = editor.getText()
    grammar = editor.getGrammar()

    lines = grammar.tokenizeLines(text)

    for line in lines
      lineElement = container.ownerDocument.createElement("div")
      lineElement.className = "line"
      container.appendChild(lineElement)

      scopeStack = [lineElement]

      for token in line
        @updateScopeStack(scopeStack, token.scopes)
        scopeStack[scopeStack.length - 1].appendChild(container.ownerDocument.createTextNode(token.value))

  addThemeStyles: (doc) ->
    themes = atom.themes.getActiveThemes()
    syntaxThemes = themes.filter (theme) -> theme.metadata.theme is 'syntax'
    for syntaxTheme in syntaxThemes
      for sheet in syntaxTheme.stylesheets
        style = doc.createElement("style")
        style.textContent = sheet[1]
        doc.head.appendChild(style)

  updateScopeStack: (scopeStack, desiredScopeDescriptor) ->
    # Find a common prefix
    for scope, i in desiredScopeDescriptor
      break unless i + 1 < scopeStack.length && scopeStack[i + 1]._scope is desiredScopeDescriptor[i]

    # Pop any extra scopes
    scopeStack.splice(i + 1)

    # Push onto common prefix until scopeStack equals desiredScopeDescriptor
    for j in [i...desiredScopeDescriptor.length]
      @pushScope(scopeStack, desiredScopeDescriptor[j])

  pushScope: (scopeStack, scope) ->
    element = scopeStack[0].ownerDocument.createElement("span")
    element.className = scope.replace(/\.+/g, ' ')
    element._scope = scope
    scopeStack[scopeStack.length - 1].appendChild(element)
    scopeStack.push(element)
