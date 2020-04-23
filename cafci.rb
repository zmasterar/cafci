require 'dotenv/load'
require 'httparty'

today=Date.today
yesterday=today.prev_day
fondos = [
  {nombre: "Consultatio Retorno Absoluto - Clase A", fondo: 662, clase: 1367},
  {nombre: "Cohen Renta Fija Dolares - Clase A", fondo: 803, clase: 2088}
]
print "Fecha desde (Formato YYYY-MM-DD. Si es ayer apretar Enter): "
start = gets.chomp
start = yesterday.strftime("%Y-%m-%d") if start == ""

print "Fecha hasta (Formato YYYY-MM-DD. Si es hoy apretar Enter): "
finish = gets.chomp
finish = today.strftime("%Y-%m-%d") if finish == ""

message_endpoint="https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_KEY']}/sendMessage?chat_id=#{ENV['CHAT_ID']}&parse_mode=markdown&text="

while true do
  time = Time.now
  response = HTTParty.get("https://api.cafci.org.ar/fondo/662/clase/1367/rendimiento/#{start}/#{finish}").body
  break if response != '{"error":"inexistence"}'
  puts "#{time.strftime("%d/%m/%Y - %H:%M:%S")} - Sin cambios"
  sleep 10
end

#HTTParty.get(message_endpoint+"Actualizaron los FCI")
#HTTParty.post(ENV["WEBHOOK_URL"],
#              content_type: "application/json",
#              body: {content: "La CAFCI ya tiene datos actualizados para hoy"})

fondos.each do |fondo|
  datos_fondo = JSON.parse(HTTParty.get("https://api.cafci.org.ar/fondo/#{fondo[:fondo]}/clase/#{fondo[:clase]}/rendimiento/#{start}/#{finish}").body)
  puts "#{fondo[:nombre]} | Valor #{start}: #{datos_fondo["data"]["desde"]["valor"].to_s} | Valor #{finish}: #{datos_fondo["data"]["hasta"]["valor"].to_s} | Rendimiento: #{datos_fondo["data"]["rendimiento"].to_s}"

  HTTParty.get(message_endpoint+<<-HEREDOC
  *#{fondo[:nombre]}*%0A
  %0A
  Valor *#{start}*: `#{datos_fondo["data"]["desde"]["valor"].to_s}%0A`
  Valor *#{finish}*: `#{datos_fondo["data"]["hasta"]["valor"].to_s}%0A`
  Rendimiento: `#{datos_fondo["data"]["rendimiento"].to_s}`
  HEREDOC
  )
end