HOWTO pw as a webmail-system

1. make messages visible to the server
 ~ ln -s /home/hyper/.mail/2016 domain/hostname

2. browse messages. to see all of today's messages:
 $ firefox hostname/today
  domain/localhost/2016/01/16/msg.ABCD on the filesystem is made accessible at
  http://localhost/2016/01/16/msg.ABCD.html

NOTE links use archive-location, original messages can be removed
 message filenames begin with msg or end with eml or FILE(1) will be invoked
 all output is contained in address/ for easy removal or one-path server route-handling
