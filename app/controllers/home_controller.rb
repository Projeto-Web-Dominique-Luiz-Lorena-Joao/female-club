class HomeController < ApplicationController
  before_action :authenticate_user!

  def dashboard
    # KPIs
    @vendas_mes = '6.800,00'
    @total_vendas = 342
    @clientes_ativos = 156
    @estoque_baixo = 12

    # Dados do gráfico de vendas (últimos 8 meses)
    @vendas_data = [4500, 5200, 4800, 6200, 6000, 6500, 7500, 8000]

    # Produtos mais vendidos
    @produtos_mais_vendidos = [
      { nome: 'Blusa Floral', unidades: 45, valor: '3.375,00' },
      { nome: 'Calça Jeans', unidades: 38, valor: '4.940,00' },
      { nome: 'Vestido Longo', unidades: 32, valor: '4.480,00' },
      { nome: 'Saia Midi', unidades: 28, valor: '2.240,00' },
      { nome: 'Blusa Básica', unidades: 25, valor: '1.250,00' }
    ]
  end
end