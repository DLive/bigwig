%%
%% show details on the VM, releases, apps, etc.
%%
-module(bigwig_http_static).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).

-export([html/1, css/1, js/1]).

-compile(export_all).

init({tcp, http}, Req, []) ->
  {ok, Req, undefined_state};
init({tcp, http}, Req, OnlyFile) ->
  {ok, Req, OnlyFile}.

handle(Req, undefined_state = State) ->
  io:format("static undefined_state~n"),
  {Path, Req2} = cowboy_req:path(Req), % strip <<"static">>
  send(Req2, Path, State);

handle(Req, OnlyFile = State) ->
  io:format("static OnlyFile~n"),
  send(Req, OnlyFile, State).

send(Req, PathBins, State) when is_binary(PathBins) ->
    send(Req, [PathBins], State);

send(Req, PathBins, State) ->
  Path = [ binary_to_list(P) || P <- PathBins ],
  io:format("static Path :~p~n",[Path]),
  case file(filename:join(Path)) of
    {ok, Body} ->
      Headers = [{<<"Content-Type">>, <<"text/html">>}],
      {ok, Req2} = cowboy_req:reply(200, Headers, Body, Req),
      {ok, Req2, State};
    _Unkonow ->
      io:format("static send :~p~n",[_Unkonow]),
      {ok, Req2} = cowboy_req:reply(404, [], <<"404'd">>, Req),
      {ok, Req2, State}
  end.

terminate(_Req, _State) ->
  ok.

html(Name) ->
  type("html", Name).
css(Name) ->
  type("css", Name).
js(Name) ->
  type("js", Name).

type(Type, Name) ->
  file(filename:join([Type, Name ++ Type])).

file(Path) ->
  Priv = priv(),
  io:format("Path Priv:~p~n",[filename:join(Priv, Path)]),
  file:read_file(filename:join(Priv, Path)).

priv() ->
  case code:priv_dir(bigwig) of
    {error,_} -> "priv";
    Priv -> Priv
  end.
