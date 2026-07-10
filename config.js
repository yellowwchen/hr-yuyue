// ============================================================
//  云端后端配置（稳定公网部署用）
//
//  1) 打开 https://supabase.com 免费注册，新建一个项目
//  2) 在 项目 Settings -> API 找到「Project URL」与「anon public key」
//  3) 把下面两个值替换掉（不要带引号外的多余空格）
//  4) 在 Supabase 的 SQL Editor 里执行 supabase/schema.sql 建表并放开权限
//  5) 刷新页面即可，无需重启
//
//  说明：anon key 设计为可暴露在前端；本 MVP 通过 RLS 策略允许匿名读写，
//  仅适合内部工具。后续接入企业微信登录后可收紧为仅登录用户可写。
// ============================================================
window.APP_CONFIG = {
  SUPABASE_URL: 'https://yfufaprvfpumrflmavme.supabase.co',
  SUPABASE_ANON_KEY: 'sb_publishable_uZHKlzZoJkef-QO_A1gWBw_XQw7hSpN'
};
