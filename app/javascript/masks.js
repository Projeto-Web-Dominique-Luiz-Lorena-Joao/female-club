// app/javascript/masks.js
// VERSÃO FINAL - Garante funcionamento

console.log('🚀 masks.js carregado!');

function aplicarMascarasCPFeTelefone() {
  console.log('🎭 Aplicando máscaras...');

  // ==========================================
  // MÁSCARA DE CPF
  // ==========================================
  const cpfInputs = document.querySelectorAll('input[name="employee[cpf]"], input[name*="[cpf]"]');
  console.log(`📝 Campos CPF encontrados: ${cpfInputs.length}`);

  cpfInputs.forEach((input, index) => {
    // Evitar aplicar múltiplas vezes
    if (input.dataset.mascaraCpf === 'aplicada') {
      console.log(`⏭️ CPF ${index + 1} já tem máscara`);
      return;
    }

    input.dataset.mascaraCpf = 'aplicada';

    input.addEventListener('input', function(e) {
      let value = e.target.value.replace(/\D/g, '');

      if (value.length > 11) {
        value = value.slice(0, 11);
      }

      if (value.length > 9) {
        value = value.replace(/(\d{3})(\d{3})(\d{3})(\d{2})/, '$1.$2.$3-$4');
      } else if (value.length > 6) {
        value = value.replace(/(\d{3})(\d{3})(\d{1,3})/, '$1.$2.$3');
      } else if (value.length > 3) {
        value = value.replace(/(\d{3})(\d{1,3})/, '$1.$2');
      }

      e.target.value = value;
    });

    console.log(`✅ Máscara CPF aplicada no campo ${index + 1}`);
  });

  // ==========================================
  // MÁSCARA DE TELEFONE
  // ==========================================
  const phoneInputs = document.querySelectorAll('input[name="employee[phone]"], input[name*="[phone]"]');
  console.log(`📞 Campos Telefone encontrados: ${phoneInputs.length}`);

  phoneInputs.forEach((input, index) => {
    // Evitar aplicar múltiplas vezes
    if (input.dataset.mascaraTelefone === 'aplicada') {
      console.log(`⏭️ Telefone ${index + 1} já tem máscara`);
      return;
    }

    input.dataset.mascaraTelefone = 'aplicada';

    input.addEventListener('input', function(e) {
      let value = e.target.value.replace(/\D/g, '');

      if (value.length > 11) {
        value = value.slice(0, 11);
      }

      if (value.length > 10) {
        value = value.replace(/(\d{2})(\d{5})(\d{4})/, '($1) $2-$3');
      } else if (value.length === 10) {
        value = value.replace(/(\d{2})(\d{4})(\d{4})/, '($1) $2-$3');
      } else if (value.length > 6) {
        value = value.replace(/(\d{2})(\d{4,5})(\d{0,4})/, '($1) $2-$3');
      } else if (value.length > 2) {
        value = value.replace(/(\d{2})(\d{0,5})/, '($1) $2');
      } else if (value.length > 0) {
        value = value.replace(/(\d{0,2})/, '($1');
      }

      e.target.value = value;
    });

    console.log(`✅ Máscara Telefone aplicada no campo ${index + 1}`);
  });

  if (cpfInputs.length > 0 || phoneInputs.length > 0) {
    console.log('✅✅✅ MÁSCARAS ATIVADAS COM SUCESSO! ✅✅✅');
  } else {
    console.warn('⚠️ Nenhum campo encontrado nesta página');
  }
}

// ==========================================
// EVENTOS PARA GARANTIR EXECUÇÃO
// ==========================================

// 1. DOMContentLoaded (padrão)
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', aplicarMascarasCPFeTelefone);
  console.log('📌 Aguardando DOMContentLoaded...');
} else {
  console.log('📌 DOM já carregado, aplicando agora...');
  aplicarMascarasCPFeTelefone();
}

// 2. Turbo (Rails 7)
document.addEventListener('turbo:load', () => {
  console.log('📌 Evento turbo:load disparado');
  aplicarMascarasCPFeTelefone();
});

// 3. Turbo frame
document.addEventListener('turbo:frame-load', () => {
  console.log('📌 Evento turbo:frame-load disparado');
  aplicarMascarasCPFeTelefone();
});

// 4. Backup - executa após 1 segundo
setTimeout(() => {
  console.log('📌 Backup: aplicando após 1s...');
  aplicarMascarasCPFeTelefone();
}, 1000);

console.log('✅ Sistema de máscaras configurado!');