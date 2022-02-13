require 'dotenv/load'
require 'httparty'
require 'date'
message_endpoint="https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_KEY']}/sendMessage?chat_id=#{ENV['CHAT_ID']}&parse_mode=markdown&text="
fondos = [
  { nombre: 'Mercado Fondo - Clase A', fondo: 798, clase: 1982 }
]
File.write("log.txt", "\n#{Time.now.strftime("%d/%m/%Y - %H:%M:%S")} - EMPIEZA EJECUCIÓN\n", mode: "a")
if ARGV.count==2
  start=ARGV[0]
  finish=ARGV[1]
elsif ARGV.count==0
  if Time.now.wday == 6 or Time.now.wday == 0 #Sábado o domingo
    File.write("log.txt", "es fin de semana\n", mode: "a")
    exit(0)
  elsif Time.now.wday == 1 #Lunes
    start=Date.today.prev_day(3).strftime("%Y-%m-%d")
  else #Martes a viernes
    start=Date.today.prev_day .strftime("%Y-%m-%d")
  end
  finish=Date.today.strftime("%Y-%m-%d")
else
  File.write("log.txt", "Wrong number of arguments (must be 0 or 2)\n", mode: "a")
  exit(1)
end

fondos.each do |fondo|
  query_url="https://api.cafci.org.ar/fondo/#{fondo[:fondo]}/clase/#{fondo[:clase]}/rendimiento/#{start}/#{finish}"
  while true do
    time = Time.now
    if time.hour >= 23
      File.write("log.txt", "Ya son las 23 y no hubo actualización, gracias vuelvas prontos\n", mode: "a")
      exit(1)
    end
    response = HTTParty.get(query_url).body
    break if response != '{"error":"inexistence"}'
    File.write("log.txt", "#{time.strftime("%d/%m/%Y - %H:%M:%S")} - Sin datos\n", mode: "a")
    sleep 10
  end

  datos_fondo = JSON.parse(HTTParty.get(query_url).body)
  File.write("log.txt", "#{fondo[:nombre]} | Valor #{start}: #{datos_fondo["data"]["desde"]["valor"].to_s} | Valor #{finish}: #{datos_fondo["data"]["hasta"]["valor"].to_s} | Rendimiento: #{datos_fondo["data"]["rendimiento"].to_s}\n", mode: "a")

  HTTParty.get(message_endpoint+<<-HEREDOC
  *#{fondo[:nombre]}*%0A
  %0A
  Valor *#{start}*: `#{datos_fondo["data"]["desde"]["valor"].to_s}%0A`
  Valor *#{finish}*: `#{datos_fondo["data"]["hasta"]["valor"].to_s}%0A`
  Rendimiento: `#{datos_fondo["data"]["rendimiento"].to_s}`
  HEREDOC
  )
end


#HTTParty.get(message_endpoint+"Actualizaron los FCI")
#HTTParty.post(ENV["WEBHOOK_URL"],
#              content_type: "application/json",
#              body: {content: "La CAFCI ya tiene datos actualizados para hoy"})