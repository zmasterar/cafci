require 'dotenv/load'
require 'httparty'
require 'date'
message_endpoint="https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_KEY']}/sendMessage?chat_id=#{ENV['CHAT_ID']}&parse_mode=markdown&text="
fondos = [
  {nombre: "Consultatio Retorno Absoluto - Clase A", fondo: 662, clase: 1367},
  {nombre: "Cohen Renta Fija Dolares - Clase A", fondo: 803, clase: 2088}
]

if ARGV.count==2
  start=ARGV[0]
  finish=ARGV[1]
elsif ARGV.count==0
  if Time.now.wday == 6 or Time.now.wday == 0 #Sábado o domingo
    puts "es fin de semana"
    exit(0)
  elsif Time.now.wday == 1 #Lunes
    start=Date.today.prev_day(3).strftime("%Y-%m-%d")
  else #Martes a viernes
    start=Date.today.prev_day .strftime("%Y-%m-%d")
  end
  finish=Date.today.strftime("%Y-%m-%d")
else
  puts "Wrong number of arguments (must be 0 or 2)"
  exit(1)
end

while true do
  time = Time.now
  if time.hour >= 23
    puts "Ya son las 23 y no hubo actualización, gracias vuelvas prontos"
    exit(1)
  end
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