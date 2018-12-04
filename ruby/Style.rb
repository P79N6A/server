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

    def self.colorize k, bg = true
      return '' if !k || k.empty? || k.match(/^[0-9]+$/)
      "#{bg ? 'color' : 'background-color'}: black; #{bg ? 'background-' : ''}color: #{'#%06x' % (rand 16777216)}"
    end
    def self.colorizeBG k; colorize k end
    def self.colorizeFG k; colorize k, false end

  end
  module HTTP
    def favicon
      '/.conf/icon.png'.R.env(env).fileResponse
    end
  end
end
