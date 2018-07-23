class WebResource
  module HTML

    Icons = {
      'uri' => :id,
      Abstract => :quote,
      BlogPost => :pencil,
      Cache => :chain,
      Comments => :comments,
      Container => :dir,
      Contains => :bin,
      Content => :pencil,
      DC+'List' => :list,
      DC+'hasFormat' => :file,
      DC+'link' => :chain,
      Date => :date,
      Identifier => :barcode,
      Image => :img,
      InstantMessage => :comment,
      Label => :tag,
      Mtime => :time,
      RSS+'comments' => :comments,
      SIOC+'ChatLog' => :comments,
      SIOC+'Discussion' => :comments,
      SIOC+'Feed' => :feed,
      SIOC+'MailMessage' => :envelope,
      SIOC+'MicroblogPost' => :newspaper,
      SIOC+'Post' => :newspaper,
      SIOC+'SourceCode' => :code,
      SIOC+'Thread' => :openenvelope,
      SIOC+'Tweet' => :bird,
      SIOC+'Usergroup' => :group,
      SIOC+'WikiArticle' => :pencil,
      SIOC+'has_creator' => :user,
      SIOC+'has_discussion' => :comments,
      SIOC+'num_replies' => :comments,
      SIOC+'reply_of' => :reply,
      SIOC+'user_agent' => :mailer,
      Schema+'Person' => :user,
      Schema+'location' => :location,
      Size => :size,
      Sound => :speaker,
      Stat+'Archive' => :archive,
      Stat+'DataFile' => :tree,
      Stat+'File' => :file,
      Stat+'HTMLFile' => :html,
      Stat+'MarkdownFile' => :markup,
      Stat+'TextFile' => :textfile,
      Stat+'WordDocument' => :word,
      Stat+'container' => :dir,
      Stat+'contains' => :dir,
      Stat+'height' => :height,
      Stat+'width' => :width,
      Title => :title,
      To => :userB,
      Type => :type,
      Video => :video,
      W3+'2000/01/rdf-schema#Resource' => :node,
    }

  end
  module HTTP

    Font = -> re {
      location = '/.conf/font.woff'
      if re.path == location
        re.fileResponse
      elsif re.path == '/css'
        [200, {'Content-Type' => 'text/css'},
         ["* {background-color: #000; color: #fff; font-family: sans-serif}
div,p,span,td {background-color: #000 !important; color: #fff !important}
a {text-decoration:none; font-weight: bold; color: #0f0 !important}
header, nav, footer {display: none}"]]
      else
        [301, {'Location' => location, 'Access-Control-Allow-Origin' => '*'}, []]
      end}

    %w{fonts.googleapis.com fonts.gstatic.com use.typekit.net}.map{|host|
      Host[host] = Font}

    Host['*.cloudfront.net'] = -> re {
      puts :WILD,re.uri
      [200,{},['cloud']]
    }
  end

end
