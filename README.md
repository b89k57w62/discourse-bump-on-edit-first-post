# Discourse Bump on Edit First Post

A Discourse plugin that automatically bumps topics to the top of the list when the first post is edited, but only for topics with specific tags.

## Installation

Add the plugin repository to your `app.yml` file:

```yaml
hooks:
  after_code:
    - exec:
        cd: $home/plugins
        cmd:
          - git clone https://github.com/discourse/discourse-bump-on-edit-first-post.git
```

Rebuild your Discourse container:

```bash
cd /var/discourse
./launcher rebuild app
```

Enable the plugin in Admin → Plugins → Settings:

- Check "bump on first post edit enabled"
- Configure allowed tags (default: "level1|level2|level3")
- Set excluded categories if needed

## Usage

Once installed, topics will automatically be bumped to the top of the topic list when users edit the first post, but only if the topic has one of the configured tags. The plugin prevents bumping for excluded categories and requires no additional user interaction. 