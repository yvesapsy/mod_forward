Purpose:
=========

Used in ejabberd chat server to forward chat messages as post requests to an arbitrary url.

Note:
==========

Tested only on ejabberd 14.07.

Installing:
==========

* Make sure you have erlang installed on the machine you are building from
  * You probably want this to be the same machine you intend to install/run ejabberd on. I'm not sure about the interoperability of ejabberd/erlang versions.
* Open the Emakefile and change ```/opt/ejabberd-14.07/lib/ejabberd-14.07/include/``` to the correct path on your machine
* Run the build.sh script to build *.beam files
* Copy the *.beam files from the ebin directory to the location where the other modules are for your server (in my case was ```/opt/ejabberd-14.07/lib/ejabberd-14.07/ebin```)
* Add the configuration shown below to your ejabberd.cfg file, providing the correct values for auth\_token, and post\_url

Example Configuration:
=====================

	% configuration for ejabberd upto version 13.10
	{mod_forward_msg, [
		{auth_token, "offline_post_auth_token"},
		{post_url, "http://localhost:4567/message_post"}
	]}

    # configuration for ejabberd >= 13.10
	mod_forward_msg:
		auth_token: "offline_post_auth_token"
		post_url: "http://localhost:4567/offline_post"

Results:
========

The application running at the post_url will receive a post http request with the following form parameters.

	"to"=>"adam2@localhost"
	"from"=>"adam1"
	"body"=>"Does it still work?"
	"access_token"=>"offline_post_auth_token"

License
========
This module is completely based on mod\_interact by Adam Duke <adam.v.duke@gmail.com>, which was almost entirely based on mod\_offline\_prowl written by Robert George <rgeorge@midnightweb.net>.
They retain the original author's license.

The original repository of mod\_interact by Adam Duke can be found [here](https://github.com/adamvduke/mod_interact)

And the original post about mod\_offline\_prowl can be found [here](http://www.unsleeping.com/2010/07/31/prowl-module-for-ejabberd/)
