# Commitlint Buildkite Plugin

Runs commitlint and validate commit conventions for your repository.

It is expected to only __run__ in builds triggered by pull requests as it will make an api call to Github to calculate the amount of commits included in the change set. With that `commits` number, it will call `commitlint` with:

```
npx -y commitlint --from HEAD~$commits --to HEAD
```

which will lint __all__ commits in the proposed PR

## Example

Add the following to your `pipeline.yml`:

```yml
steps:
  - plugins:
      - minutebook/commitlint#v1.0.0: ~
```

## Configuration

### `github_token` (Required, string)

A Github personal access token with enough permission to read the repository pull requests - [Fine grained personal access tokens](https://github.blog/2022-10-18-introducing-fine-grained-personal-access-tokens-for-github/) are recommended

### `node_version` (Optional, string)

The tag of the docker node image to use for running `commitlint` - Avaialable tags can be found [here](https://hub.docker.com/_/node)


## Developing

To run the tests:

```shell
docker-compose run --rm tests
```

## Contributing

1. Fork the repo
2. Make the changes
3. Run the tests
4. Commit and push your changes
5. Send a pull request