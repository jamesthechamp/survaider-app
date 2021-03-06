
Onboarding =
  slides:
    init: (slide)->
      for name, obj of @meta
        obj.init()

      @prevel = $('a[role="prev"]')
      @nextel = $('a[role="next"]')
      @skipel = $('a[role="skip"]')

      @slides = $("div[data-slide]")
      @slidetitles = $("li[data-slide-title]")
      @activate @slides.eq(0).attr 'data-slide'
      if slide
        @activate slide

      @prevel.on 'click', => @previous()
      @nextel.on 'click', => @next()
      @skipel.on 'click', => @skip()

      for title in @slidetitles
        $(title).on 'click', (e) =>
          el = $(e.delegateTarget)
          if el.hasClass('filled')
            @activate el.attr('data-slide-title')

    activate: (name)->
      @slides.removeClass 'active'
      @slidetitles.removeClass 'active'
      @slidetitles.removeClass 'filled'

      if @meta[name]?.can_skip
        @skipel.show()
      else
        @skipel.hide()

      el = $("div[data-slide=#{name}]")
      el.addClass 'active'
      index = @slides.index(el)

      if @meta[name]?.prepare?
        @meta[name].prepare(@meta)

      if index is 0
        @prevel.hide()
      else
        @prevel.show()

      translate = -1 * index * el.outerWidth()
      $('div[data-slides]').css 'transform', "translateX(#{translate}px)"

      title = $("li[data-slide-title=#{name}")
      title.addClass 'active'
      title.prevAll('li[data-slide-title]').addClass 'filled'

    __paginate: (operator, skipping)->
      current = $("div[data-slide].active")
      current_name = current.attr 'data-slide'

      if skipping and @meta[current_name].can_skip
        @meta[current_name].skip()

      if operator is 1 and @meta[current_name].next
        return @meta[current_name].next()

      if operator is 1 and not @meta[current_name]?.validate()
        vex.dialog.alert
          className: 'vex-theme-default'
          message: @meta[current_name]?.validation_error
        return

      index = @slides.index current
      if index < (@slides.length - 1) and operator is 1
        @activate @slides.eq(index + operator).attr 'data-slide'
      else if operator is -1 and index > 0
        @activate @slides.eq(index + operator).attr 'data-slide'

    next: ->
      @__paginate(1)

    skip: ->
      @__paginate(1, true)

    previous: ->
      @__paginate(-1)

    meta:
      'key-aspect':
        validation_error: """Business name and at least one
        keyword is required."""
        can_skip: no

        init: ->
          @slide = $('div[data-slide="key-aspect"]')
          @el = @slide.find('select[data-onboarding-input]')
          @el.select2
            tags: true
            tokenSeparators: [',', ';']
        serialize: ->
          {
            key_aspects: @el.val()
            survey_name: @slide.find('input').val()
          }
        validate: ->
          {key_aspects, survey_name} = @serialize()
          return (
            key_aspects and
            key_aspects.length > 0 and
            survey_name and
            survey_name.length > 1
          )

      'business-units':
        validation_error: 'Please enter correct values.'
        can_skip: yes

        init: ->
          @parent = $('ul[role="unit-input"]')
          templateel = @parent.find 'li[role="template"]'
          @template = templateel.clone()
          templateel.remove()
          @parent.prev('.header').hide()

          @add_field()
          @parent.siblings('a[role="add"]').on 'click', =>
            @add_field()

        skip: ->
          @parent.find('.header').hide()
          @parent.find('li[role="input"]').remove()

        add_field: ->
          el = $("<li role='input'>#{@template.html()}</li>")
          @parent.append el
          @parent.prev('.header').show()
          @parent.animate
            scrollTop: 1000
          el.find('a[role="deleteorb"]').on 'click', =>
            el.remove()
            if @parent.children().length is 0
              @parent.prev('.header').hide()

        serialize: ->
          units = @parent.find('li[role="input"]')
          out = []
          for unitel in units
            unit = $ unitel
            out.push
              unit_name: unit.find('input[type="text"]').val()
              owner_mail: unit.find('input[type="email"]').val()
          return out

        validate: ->
          values = @serialize()
          if values.length is 0 then return false

          for {unit_name, owner_mail} in values
            if not unit_name or unit_name.length < 1
              return false
            if not owner_mail or owner_mail.length < 2
              return false

          (_.uniq values, 'unit_name').length is values.length

      'facebook':
        validation_error: 'Facebook URI incorrect? <insert your msg>'
        can_skip: yes

        init: -> @el = $("div[data-slide='facebook']")
        skip: ->
        serialize: -> @el.find('input').val()
        validate: -> true

      'twitter':
        validation_error: 'Twitter URI incorrect'
        can_skip: yes
        init: -> @el = $("div[data-slide='twitter']")
        skip: ->
        serialize: -> @el.find('input').val()
        validate: -> true

      'websites':
        validation_error: 'Websites incorrect'
        can_skip: yes
        init: ->
          @el = $("div[data-slide='websites']")
          @container = $("ul[role='user-input']")
          templateel = @el.find 'li[role="template"]'
          @template = templateel.clone()
          templateel.remove()
        skip: ->
        prepare: (meta) ->
          @container.html('')
          units = meta['business-units'].serialize()
          for {unit_name} in units
            el = $("<li role='input'>#{@template.html()}</li>")
            (el.find 'label').html(unit_name)
            (el.find 'input').attr('data-unit', unit_name)
            @container.append el

        serialize: ->
          inputs = @container.find 'input'
          vals   = {}

          inputs.each ->
            el    = $(@)
            fr    = el.attr 'for'
            val   = el.val()
            unit  = el.attr 'data-unit'

            unless val.length then return

            unless vals[unit]
              vals[unit] = {}

            vals[unit][fr] = val

          return vals

        validate: -> true
        next: -> Onboarding.overlay.activate('review')

  overlay:
    init: ->
      for name, obj of @meta
        obj.init()
      @elements = $('div[role="overlay"]')
      @close()

    activate: (name, args)->
      @close()
      target = $("div[data-overlay='#{name}'")
      @meta[name].pre_show?(args)
      target.addClass('visible')

    close: ->
      @elements.removeClass('visible')

    meta:
      review:
        init: ->
          @el = $("div[data-overlay='review'")

          (@el.find 'p[role="buttons"]').slideDown()
          (@el.find 'p[role="progress"]').slideUp()

          (@el.find 'a[role="close"]').on 'click', ->
            Onboarding.overlay.close()
          (@el.find 'a[role="proceed"]').on 'click', =>
            @do_proceed()

        pre_show: ->
          @preset = false
          rel = @el.find('dl[role="review-fields"]')
          render =
            'key-aspect': (dat) ->
              {key_aspects, survey_name} = dat
              out = "<dt>Survey Name</dt><dd>#{survey_name}</dd>"
              tags = (for tag in key_aspects
                "<span role='tag'>#{tag}</span>").join("")
              out += "<dt>Key Aspects</dt><dd>#{tags}</dt>"
              return out

            'business-units': (dat) ->
              units = for {unit_name, owner_mail} in dat
                "<li>#{unit_name} <small>(#{owner_mail})</small></li>"
              units = if units.length then units.join("") else "Skipped"
              "<dt>Units</dt><dd><ul>#{units}</ul></dd>"

            'facebook': (dat) ->
              val = if dat.length then dat else "Skipped"
              "<dt>Facebook</dt><dd>#{val}</dd>"

            'twitter': (dat) ->
              val = if dat.length then dat else "Skipped"
              "<dt>Twitter</dt><dd>#{val}</dd>"

            'websites': (dat) ->
              out = ""
              for k, v of dat
                out += """<li>#{k}: #{if v.zomato then "zomato" else ""}
                  #{if v.tripadvisor then 'tripadvisor' else ""} </li>"""

              unless out.length then out = "skipped"

              "<dt>External Services</dt><dd><ul>#{out}</ul></dd>"

          meta = Onboarding.slides.meta
          htmlgen = (render[k](v.serialize()) for k, v of meta)
          @preset = true
          rel.html(htmlgen.join(''))

        do_proceed: ->
          if @preset? isnt true then return
          (@el.find 'p[role="buttons"]').slideUp()
          (@el.find 'p[role="progress"]').slideDown()

          data =
            bulk: true
            payload: JSON.stringify
              create: Onboarding.slides.meta['key-aspect'].serialize()
              units: Onboarding.slides.meta['business-units'].serialize()
              social:
                facebook: Onboarding.slides.meta['facebook'].serialize()
                twitter: Onboarding.slides.meta['twitter'].serialize()
              services: Onboarding.slides.meta['websites'].serialize()

          $.ajax(
            url: '/api/survey'
            data: data
            type: 'POST'
          ).done((dat) =>
            Onboarding.overlay.activate 'success',
              success: if dat?.partial is false then true else false
              uri: dat?.uri_edit
              id: dat?.id

          ).fail(=>
            vex.dialog.alert
              className: 'vex-theme-default'
              message: "Unknown server error. Please try again."

            (@el.find 'p[role="buttons"]').slideDown()
            (@el.find 'p[role="progress"]').slideUp()
            return
          )

      success:
        msg_fail: """Your survey has been succesfully created, however a few
        of the unit owners you had designated weren't added because they're
        already owners of another survey. No worries, though. You can always
        share the units from your dashboard."""
        msg_success: """Your survey has been succesfully created."""

        init: ->
          @el = $("div[data-overlay='success'")

        pre_show: (status)->
          (@el.find '[role="edit"]').attr 'href', status?.uri or '#'
          (@el.find '[role="dashboard"]').attr 'href', "/survey/s:#{status?.id}/analysis?parent=true" or '#'
          (@el.find '[role="message"]').html(
            if status?.success then @msg_success else @msg_fail
          )

  init: ->
    $('#onboarding').html(Survaider.Templates['dashboard.onboarding.dock']())

    @slides.init()
    @overlay.init()

$(document).ready ->
  Onboarding.init()

window.Onboarding = Onboarding
