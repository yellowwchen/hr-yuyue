// ============================================================
//  数据层：基于 Supabase 的云端存储 + 实时推送
//  前端只通过该模块读写预约，不直接碰接口，方便日后替换后端。
// ============================================================
const DB = (() => {
  let client = null;

  function cfg() {
    return window.APP_CONFIG || {};
  }

  function isConfigured() {
    const c = cfg();
    return c.SUPABASE_URL && c.SUPABASE_ANON_KEY &&
      !c.SUPABASE_URL.startsWith('YOUR_') && !c.SUPABASE_ANON_KEY.startsWith('YOUR_');
  }

  async function init() {
    if (!isConfigured()) throw new Error('NOT_CONFIGURED');
    if (!window.supabase || !window.supabase.createClient) {
      throw new Error('Supabase SDK 未加载（请检查网络）');
    }
    client = window.supabase.createClient(cfg().SUPABASE_URL, cfg().SUPABASE_ANON_KEY);
    return client;
  }

  function mapRow(r) {
    return {
      id: r.id,
      oaAccount: r.oa_account,
      bizType: r.biz_type,
      location: r.location,
      date: r.date,
      time: r.time,
      status: r.status,
      createdAt: r.created_at
    };
  }

  async function list() {
    const { data, error } = await client
      .from('reservations')
      .select('*')
      .order('created_at', { ascending: false });
    if (error) throw error;
    return (data || []).map(mapRow);
  }

  async function create(r) {
    const { data, error } = await client
      .from('reservations')
      .insert([{
        oa_account: r.oaAccount,
        biz_type: r.bizType,
        location: r.location,
        date: r.date,
        time: r.time,
        status: 'pending'
      }])
      .select()
      .single();
    if (error) throw error;
    return mapRow(data);
  }

  async function update(id, status) {
    const { data, error } = await client
      .from('reservations')
      .update({ status })
      .eq('id', id)
      .select()
      .single();
    if (error) throw error;
    return mapRow(data);
  }

  // 订阅整张表的增删改，任一端变化即触发回调（真正的实时推送）
  function subscribe(cb) {
    if (!client) return;
    client
      .channel('reservations-room')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'reservations' }, () => cb())
      .subscribe();
  }

  return { init, list, create, update, subscribe, isConfigured };
})();
