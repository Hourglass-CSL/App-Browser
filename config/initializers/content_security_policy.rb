Rails.application.config.content_security_policy_nonce_generator = ->(_request) { SecureRandom.base64(16) }

# Muy importante: SOLO script-src tendrá nonce
Rails.application.config.content_security_policy_nonce_directives = %w(script-src)

Rails.application.configure do
  config.content_security_policy do |p|
    p.default_src :self
    p.font_src    :self, :https, :data
    p.img_src     :self, :https, :data # si usas createObjectURL, cámbialo a :self, :https, :data, :blob
    p.object_src  :none

    # Scripts: más seguro con nonce (no pongas 'unsafe-inline' aquí)
    p.script_src  :self, :https

    # Estilos: permite inline (sin nonce en la directiva, para que 'unsafe-inline' sí aplique)
    p.style_src   :self, :https, :unsafe_inline

    p.connect_src :self, :https, :wss

    p.frame_ancestors :self, :https, :http
  end
end