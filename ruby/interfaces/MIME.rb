# coding: utf-8
class R
  module MIME
    # basename-prefix -> MIME
    MIMEprefix = {
      'authors' => 'text/plain',
      'changelog' => 'text/plain',
      'contributors' => 'text/plain',
      'copying' => 'text/plain',
      'install' => 'text/x-shellscript',
      'license' => 'text/plain',
      'readme' => 'text/markdown',
      'todo' => 'text/plain',
      'unlicense' => 'text/plain',
      'msg' => 'message/rfc822'}
    # basename-suffix -> MIME
    MIMEsuffix = {
      'asc' => 'text/plain',
      'chk' => 'text/plain',
      'conf' => 'application/config',
      'desktop' => 'application/config',
      'doc' => 'application/msword',
      'docx' => 'application/msword+xml',
      'dat' => 'application/octet-stream',
      'db' => 'application/octet-stream',
      'e' => 'application/json',
      'eot' => 'application/font',
      'go' => 'application/go',
      'haml' => 'text/plain',
      'hs' => 'application/haskell',
      'ini' => 'text/plain',
      'ino' => 'application/ino',
      'md' => 'text/markdown',
      'msg' => 'message/rfc822',
      'list' => 'text/plain',
      'log' => 'text/chatlog',
      'ru' => 'text/plain',
      'rb' => 'application/ruby',
      'rst' => 'text/restructured',
      'sample' => 'application/config',
      'sh' => 'text/x-shellscript',
      'terminfo' => 'application/config',
      'tmp' => 'application/octet-stream',
      'ttl' => 'text/turtle',
      'u' => 'text/uri-list',
      'woff' => 'application/font',
      'yaml' => 'text/plain'}
  end

  # file -> MIME
  def mime
    @mime ||= # memoize
      (name = path || ''
       prefix = ((File.basename name).split('.')[0]||'').downcase
       suffix = ((File.extname name)[1..-1]||'').downcase
       if node.directory? # container
         'inode/directory'
       elsif MIMEprefix[prefix] # prefix mapping
         MIMEprefix[prefix]
       elsif MIMEsuffix[suffix] # suffix mapping
         MIMEsuffix[suffix]
       elsif Rack::Mime::MIME_TYPES['.'+suffix] # suffix mapping (Rack fallback)
         Rack::Mime::MIME_TYPES['.'+suffix]
       else
         puts "#{pathPOSIX} unmapped MIME, sniffing content (SLOW)"
         `file --mime-type -b #{Shellwords.escape pathPOSIX.to_s}`.chomp
       end)
  end

  def isRDF; %w{atom n3 rdf owl ttl}.member? ext end

end

def H x # HTML from ruby values
  case x
  when String
    x
  when Hash # element
    void = [:img, :input, :link, :meta].member? x[:_]
    '<' + (x[:_] || 'div').to_s +                        # element name
      (x.keys - [:_,:c]).map{|a|                         # attribute name
      ' ' + a.to_s + '=' + "'" + x[a].to_s.chars.map{|c| # attribute value
        {"'"=>'%27', '>'=>'%3E',
         '<'=>'%3C'}[c]||c}.join + "'"}.join +
      (void ? '/' : '') + '>' + (H x[:c]) +              # children
      (void ? '' : ('</'+(x[:_]||'div').to_s+'>'))       # element closer
  when Array # structure
    x.map{|n|H n}.join
  when R
    H({_: :a, href: x.uri, c: x.label})
  when NilClass
    ''
  when FalseClass
    ''
  else
    CGI.escapeHTML x.to_s
  end
end

