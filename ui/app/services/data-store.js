import Ember from 'ember';

export default Ember.Service.extend({
  findBlock(workspace_id, memory_block_name) {
    return Ember.$.get('http://localhost:4567/api/workspaces/' + workspace_id + '/memory_blocks/' + memory_block_name);
  }
});
