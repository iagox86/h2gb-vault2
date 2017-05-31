import Ember from 'ember';
import config from './config/environment';

const Router = Ember.Router.extend({
  location: config.locationType,
  rootURL: config.rootURL
});

Router.map(function() {
  this.route('workspace', { path: '/workspaces/:workspace_id' }, function() {
    this.route('memory_block', { path: '/workspaces/:workspace_id/memory_blocks/:memory_block_name' });
  });
});

export default Router;
