var group_div =  `<div class='panel panel-default'>
                    <div class='panel-heading green'>
                      <h4 class='panel-title'>
                      <a href='#$ID' data-toggle='hcollapse' aria-expanded="false" class="collapsed"><span class="pin"></span>$TITLE</a>
                      </h4>
                    </div>
                    <div class='panel-collapse collapse' id='$ID'>
                      <div class='panel-body'>$INNER</div>
                    </div>
                  </div>`;
var inner_div   =`<div class='panel-group'>
                    $CONTENT
                  </div>`;

var app = [
  {id: '17:15:58:738', title: 'caller', context: 'START', message: 'message', dt: 'time', levels:
  [
    {id: '17:15:58:739', title: 'caller', context: 'START', message: 'message', dt: 'time', levels:
      [
        {id: '17:15:58:739', context: 'REPORT', message: 'message', dt: 'time'},
        {id: '17:15:58:741', context: 'REPORT', message: 'message', dt: 'time'},
        {id: '17:15:58:739', context: 'REPORT', message: 'message', dt: 'time'},
        {id: '17:15:58:741', context: 'END', message: 'message', dt: 'time'}
      ]
    },
    {id: '17:15:58:741', context: 'REPORT', message: 'message', dt: 'time'},
    {id: '17:15:58:741', context: 'REPORT', message: 'message', dt: 'time'},
    {id: '17:15:58:742', context: 'REPORT', message: 'message', dt: 'time'},
    {id: '17:15:58:743', context: 'END', message: 'message', dt: 'time'}
  ]}
];

/**
 * Creates a nested multi level and collapsible menu with accordion
 * @param config
 *  - An array with JSON configurations for the nested menu accordion
 *  - Example:
 *  config = [
 *              {id:'level1', title:'LEVEL 1', levels:
 *                  [
 *                      {id:'level1-1', title:'LEVEL 1-1', content:'text'},
 *                      {id:'level1-2', title:'LEVEL 1-2', content:'text'},
 *                      {id:'level1-2', title:'LEVEL 1-2', levels: [ ... ]}
 *                  ]
 *              },
 *              // Deepest element must contain "content" data to visualize
 *              {id:'level2', title:'LEVEL 2', content:'MY CONTENT'},
 *              {id:'levelN', title:'LEVEL N', content:'MY CONTENT'}
 *           ]
 */
function createAccordion(config){
  var content = '';
  config.forEach(function(level) {
    var subcontent  = group_div.replace(/\$ID/g, level.id)
      .replace('$TITLE', level.title);

    subcontent = subcontent.replace('$INNER',
      inner_div.replace('$CONTENT', typeof level.levels == 'object'
        ? createAccordion(level.levels)
        : level.content));

    content = content + subcontent;
  });
  return content;
}
$(document).ready(function() {

  config = [
    {id:'level1', title:'LEVEL 1', levels:
      [
        {id:'level1-1', title:'LEVEL 1.1', levels:
          [
            {
              id:'level1-1-1',
              title:'LEVEL 1.1.1',
              content:'Level 1.1.1 content'
            },
            {
              id:'level1-1-2',
              title:'LEVEL 1.1.2',
              content:'Level 1.1.2 content'
            }
          ]},
        {id:'level1-2', title:'LEVEL 1.2', content:'Level 1.2 content'}
      ]},
    {id:'level2', title:'LEVEL 2', content:'Level 2 content'},
    {id:'level3', title:'LEVEL 3', content:'Level 3 content'}
  ];

  var $accordion = $('#tree_accordion').html(createAccordion(config));

  $('.panel').on('pinchange', function (e, state) {
    e.stopPropagation();
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
