module.exports =
  base-props: (req, res, next) ->
    res.locals.{}props.base = true;
    next!
