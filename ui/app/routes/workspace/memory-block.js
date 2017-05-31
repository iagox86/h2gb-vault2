import Ember from 'ember';

export default Ember.Route.extend({
  model: function(params) {
    return Ember.$.get('http://localhost:4567/api/workspaces/' + params.workspace_id + '/memory_blocks/' + params.memory_block_name);
  },
});
