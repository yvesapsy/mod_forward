%%%----------------------------------------------------------------------

%%% File    : mod_forward_msg.erl
%%% Author  : Yves Apsy <contact@yvesapsy.com>
%%% Purpose : Forward all chat messages to an arbitrary url
%%% Created : 12 Dec 2014 by Yves Apsy
%%% Based on: mod_offline_post by Adam Duke <adam.v.duke@gmail.com>
%%%
%%%
%%% Copyright (C) 2014   Yves Apsy
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 2 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%----------------------------------------------------------------------

-module(mod_forward_msg).
-author('contact@yvesapsy.com').

-behaviour(gen_mod).

-export([start/2,
	init/2,
	stop/1,
	send_offline_message/3,
	send_post_message/3,
	send_post_status_on/4,
	send_post_status_off/4]).

-define(PROCNAME, ?MODULE).

-include("ejabberd.hrl").
-include("jlib.hrl").
-include("logger.hrl").

start(Host, Opts) ->
%%% ?INFO_MSG("Starting mod_forward_msg", [] ),
	register(?PROCNAME,spawn(?MODULE, init, [Host, Opts])),
	ok.

init(Host, _Opts) ->
	inets:start(),
	ssl:start(),
	ejabberd_hooks:add(offline_message_hook, Host, ?MODULE, send_offline_message, 10),
	ejabberd_hooks:add(user_send_packet, Host, ?MODULE, send_post_message, 10),
	ejabberd_hooks:add(set_presence_hook, Host, ?MODULE, send_post_status_on, 10),
	ejabberd_hooks:add(unset_presence_hook, Host, ?MODULE, send_post_status_off, 10),
	ok.

stop(Host) ->
%%% ?INFO_MSG("Stopping mod_forward_msg", [] ),
	ejabberd_hooks:delete(offline_message_hok, Host, ?MODULE, send_offline_message, 10),
	ejabberd_hooks:delete(user_send_packet, Host, ?MODULE, send_post_message, 10),
	ejabberd_hooks:delete(set_presence_hook, Host, ?MODULE, send_post_status_on, 10),
	ejabberd_hooks:delete(unset_presence_hook, Host, ?MODULE, send_post_status_off, 10),
	ok.

send_offline_message(From, To, Packet) ->
	Type = xml:get_tag_attr_s(list_to_binary("type"), Packet),
	Body = xml:get_path_s(Packet, [{elem, list_to_binary("body")}, cdata]),
	Token = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, auth_token, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
	PostChatUrl = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, post_chat_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),

	if
		(Type == <<"chat">>) and (Body /= <<"">>) ->
			Sep = "&",
			Post = [
				"to=", To#jid.luser, Sep,
				"from=", From#jid.luser, Sep,
				"body=", url_encode(binary_to_list(Body)), Sep,
				"offline=true", Sep,
				"access_token=", Token],
%%%				?INFO_MSG("Sending post request to ~s with body \"~s\"", [PostChatUrl, Post]),
				httpc:request(post, {binary_to_list(PostChatUrl), [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
			ok;
		true ->
			ok
	end.


send_post_message(From, To, Packet) ->
	Type = xml:get_tag_attr_s(list_to_binary("type"), Packet),
	Body = xml:get_path_s(Packet, [{elem, list_to_binary("body")}, cdata]),
	Token = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, auth_token, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
	PostChatUrl = gen_mod:get_module_opt(To#jid.lserver, ?MODULE, post_chat_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),

	if
		(Type == <<"chat">>) and (Body /= <<"">>) ->
			Sep = "&",
			Post = [
				"to=", To#jid.luser, Sep,
				"from=", From#jid.luser, Sep,
				"body=", url_encode(binary_to_list(Body)), Sep,
				"offline=true", Sep,
				"access_token=", Token],
%%%				?INFO_MSG("Sending post request to ~s with body \"~s\"", [PostChatUrl, Post]),
				httpc:request(post, {binary_to_list(PostChatUrl), [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
			ok;
		true ->
			ok
	end.

send_post_status_on(User, Server, Resource, Packet) ->
	Jid = jlib:make_jid(User, Server, Resource),
	Status = xml:get_path_s(Packet, [{elem, list_to_binary("status")}, cdata]),
	Token = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, auth_token, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
	PostStatusUrl = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, post_status_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
	Sep = "&",
	if
		(Status /= <<"">>) ->
			Post = [
				"user_id=", Jid#jid.luser, Sep,
				"status=", Status, Sep,
				"access_token=", Token],
%%% 			?INFO_MSG("Sending post request to ~s with body \"~s\"", [PostStatusUrl, Post]),
			httpc:request(post, {binary_to_list(PostStatusUrl), [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
			none;
		true ->
			none
	end.

send_post_status_off(User, Server, Resource, Packet) ->
	Jid = jlib:make_jid(User, Server, Resource),
	Token = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, auth_token, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
	PostStatusUrl = gen_mod:get_module_opt(Jid#jid.lserver, ?MODULE, post_status_url, fun(S) -> iolist_to_binary(S) end, list_to_binary("")),
	Sep = "&",
	Post = [
		"user_id=", Jid#jid.luser, Sep,
		"status=", "Not Available", Sep,
		"access_token=", Token],
%%% 	?INFO_MSG("Sending post request to ~s with body \"~s\"", [PostStatusUrl, Post]),
	httpc:request(post, {binary_to_list(PostStatusUrl), [], "application/x-www-form-urlencoded", list_to_binary(Post)},[],[]),
	none.

%%% The following url encoding code is from the yaws project and retains it's original license.
%%% https://github.com/klacke/yaws/blob/master/LICENSE
%%% Copyright (c) 2006, Claes Wikstrom, klacke@hyber.org
%%% All rights reserved.
url_encode([H|T]) when is_list(H) ->
	[url_encode(H) | url_encode(T)];
url_encode([H|T]) ->
	if
		H >= $a, $z >= H ->
			[H|url_encode(T)];
		H >= $A, $Z >= H ->
			[H|url_encode(T)];
		H >= $0, $9 >= H ->
			[H|url_encode(T)];
		H == $_; H == $.; H == $-; H == $/; H == $: -> % FIXME: more..
			[H|url_encode(T)];
		true ->
			case integer_to_hex(H) of
				[X, Y] ->
					[$%, X, Y | url_encode(T)];
				[X] ->
					[$%, $0, X | url_encode(T)]
			end
	end;

url_encode([]) ->
	[].

integer_to_hex(I) ->
	case catch erlang:integer_to_list(I, 16) of
		{'EXIT', _} -> old_integer_to_hex(I);
		Int         -> Int
	end.

old_integer_to_hex(I) when I < 10 ->
	integer_to_list(I);
old_integer_to_hex(I) when I < 16 ->
	[I-10+$A];
old_integer_to_hex(I) when I >= 16 ->
	N = trunc(I/16),
	old_integer_to_hex(N) ++ old_integer_to_hex(I rem 16).

