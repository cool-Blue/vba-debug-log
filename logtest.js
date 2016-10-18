var group_div =  `<div class='panel panel-info container'>
                    <div class='panel-heading'>
                      <span class='panel-title'>
                        <div data-toggle='hcollapse' aria-expanded="false" class="collapsed">
                          <span class="pin"></span>
                          <span class="timestamp">$TIMESTAMP</span>
                          <span class="caller" style="margin-left: $INDENTem">$CALLER</span>
                          <span class="context">$CONTEXT</span>
                          <span class="message">$MESSAGE</span>
                          <span class="dt">$DT</span>
                        </div>
                      </span>
                    </div>
                    <div class='panel-collapse collapse'>
                      <div class='panel-body'>$INNER</div>
                    </div>
                  </div>`;
var inner_div   =`<div class='panel-group panel-title'>
                    $CONTENT
                  </div>`;
var report_div = `<div>
                    <span class="timestamp">$TIMESTAMP</span>
                    <div style="display: inline-block; margin-left: $INDENTem">
                      <span class="context">$CONTEXT</span>
                      <span class="message">$MESSAGE</span>
                    </div>
                    <span class="dt pull-right">$DT</span>
                  </div>`;
var end_div = `<div class="panel-info"><div class="panel-heading">
                    <span class="timestamp">$TIMESTAMP</span>
                    <div style="display: inline-block; margin-left: $INDENTem">
                      <span class="context">$CALLER</span>
                      <span class="context">$CONTEXT</span>
                      <span class="message">$MESSAGE</span>
                    </div>
                    <span class="dt pull-right">$DT</span>
                  </div></div>`;

/**
 * Creates a nested multi level and collapsible menu with accordion
 * @param config
 *  - An array with JSON configurations for the nested menu accordion
 *  - Example:
 *  config = [
 *              {id:'level1', title:'LEVEL 1', steps:
 *                  [
 *                      {id:'level1-1', title:'LEVEL 1-1', content:'text'},
 *                      {id:'level1-2', title:'LEVEL 1-2', content:'text'},
 *                      {id:'level1-2', title:'LEVEL 1-2', steps: [ ... ]}
 *                  ]
 *              },
 *              // Deepest element must contain "content" data to visualize
 *              {id:'level2', title:'LEVEL 2', content:'MY CONTENT'},
 *              {id:'levelN', title:'LEVEL N', content:'MY CONTENT'}
 *           ]
 */
function createAccordion(config, depth = 0){
  var content = '';
  config.forEach(function(call, i, calls) {
    var subcontent  = ['TIMESTAMP', 'CALLER', 'CONTEXT', 'MESSAGE', 'DT']
      .reduce((group, part) => {
        return group.replace(`$${part}`, call[part.toLowerCase()] || '')
      }, call.steps ? group_div : call.context === 'END' ? end_div : report_div)
      .replace('$INDENT', call.context === 'END' ? depth -1 : depth);

    if(call.steps) {
      subcontent = subcontent.replace('$INNER',
        inner_div.replace('$CONTENT', createAccordion(call.steps, depth + 1)));
    }

    content = content + subcontent;
  });
  return content;
}
$(document).ready(function() {

  var config = [
    {timestamp: '17:15:58:738', caller: 'root', context: 'CALL', message: 'message', steps:
      [
        {timestamp: '17:15:58:741', context: 'REPORT', message: 'message1', dt: 'time'},
        {timestamp: '17:15:58:741', context: 'REPORT', message: 'message1', dt: 'time'},
        {timestamp: '17:15:58:739', caller: 'sub', context: 'CALL', message: 'message', steps:
          [
            {timestamp: '17:15:58:739', context: 'REPORT', message: 'message1 message1 message1 message1 message1', dt: 'time'},
            {timestamp: '17:15:58:741', context: 'REPORT', message: 'message2', dt: 'time'},
            {timestamp: '17:15:58:739', caller: 'sub', context: 'CALL', message: 'message', steps:
              [
                {timestamp: '17:15:58:739', context: 'REPORT', message: 'message1', dt: 'time'},
                {timestamp: '17:15:58:741', context: 'REPORT', message: 'message2', dt: 'time'},
                {timestamp: '17:15:58:739', context: 'REPORT', message: 'message3', dt: 'time'},
                {timestamp: '17:15:58:741', context: 'END', message: 'end', dt: 'time'}
              ]
            },
            {timestamp: '17:15:58:739', context: 'REPORT', message: 'message3', dt: 'time'},
            {timestamp: '17:15:58:741', context: 'END', message: 'end', dt: 'time'}
          ]
        },
        {timestamp: '17:15:58:742', context: 'REPORT', message: 'message1', dt: 'time'},
        {timestamp: '17:15:58:743', context: 'END', message: 'end', dt: 'time'}
      ]}
  ];

  var $accordion = $('#tree_accordion').html(createAccordion(config));

  $('.panel').on('pinchange', function (e, state) {
    e.stopPropagation();
    e.preventDefault();
    eCollapse.call(this, e, state)
  });

  /**
   *
   * @param e {event} emitted by an accordion control element
   * @param state {object} defines the type of event
   */
  function eCollapse (e, state) {
    var isHover = state.type !== 'click',
      $panel = $(this),
      $panelTitle = $(e.target),
      collapse = $panel.children('.panel-collapse'),
      $collapse = $(collapse);

    if(isHover){
      if($collapse.hasClass('pinned')) return;
      $('.panel .panel-collapse').not(collapse).not('.pinned').collapse("hide");   // clean up
      $collapse.collapse($collapse.hasClass('in') ? 'hide' : "show");

    } else {
      $collapse.toggleClass('pinned');
      $panelTitle.toggleClass('pinned')
        .find('.pin').toggleClass('in');
      if(state.shiftKey && !$panelTitle.hasClass('pinned'))
        $collapse.find('.pinned').removeClass('pinned')
          .find('.pin').removeClass('in');
    }
  }
  function ePin (e) {
    e.stopPropagation();
    e.preventDefault();
    $(this).trigger(`pinchange`, {type: e.type, shiftKey: e.shiftKey})
  }
  $accordion.on('mouseenter', '[data-toggle=hcollapse]', ePin);
  $accordion.on('mouseout', '[data-toggle=hcollapse]', ePin);
  $accordion.on('click', '[data-toggle=hcollapse]', ePin);

});
