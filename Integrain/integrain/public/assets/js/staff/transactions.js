/* Staff transactions page (salary records and pay requests) */
(function () {
  const { $, esc, money, pillFor, dotFor, showError } = Staff;


  async function renderTransactions() {
    try {
      const { transactions } = await api('staff/transactions');
      $('staff-transactions-count').textContent = `${transactions.length} record${transactions.length === 1 ? '' : 's'}`;
      $('staff-transactions-list').innerHTML = transactions.length ? transactions.map(t => `<tr><td><i class="row-dot ${dotFor(t.txn_type)}"></i> ${esc(t.txn_type)}</td><td>${fmt.date(t.txn_date)}</td><td class="${/advance/i.test(t.txn_type) ? 'amount-negative' : 'amount-positive'}">${/advance/i.test(t.txn_type) ? '− ' : ''}${money(t.amount)}</td><td><span class="status-pill ${pillFor(t.txn_status)}">${esc(t.txn_status)}</span></td></tr>`).join('') : '<tr><td colspan="4" class="attendance-empty">No transactions yet.</td></tr>';
    } catch (error) { showError(error); }
  }

  Staff.renderTransactions = renderTransactions;
})();
