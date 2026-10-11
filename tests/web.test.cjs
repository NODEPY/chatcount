const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const html = fs.readFileSync(require('node:path').join(__dirname,'../web/ChatCount.html'),'utf8');
const script = html.split('<script>')[1].split('</script>')[0];
new vm.Script(script);
const analysis = script.split('/* ANALYSIS_START */')[1].split('/* ANALYSIS_END */')[0];
vm.runInThisContext(analysis);
assert.deepEqual(tokens("Я П’ЯТЬ пʼять https://foo.bar email@host.com 🙂 123 а-б"),['я',"п'ять","п'ять",'а-б']);
const messages = [
 {type:'message',from:'Оля',from_id:'user1',text:'я я я не не і просто кава кава чай а-б'},
 {type:'message',from:'Богдан',from_id:'user2',text:['при',{type:'bold',text:'віт'},' привіт',{type:'link',text:'https://foo.bar'}]},
 {type:'message',from:'Оля нова',from_id:'user1',text:''},
 {type:'service',from:'Оля',from_id:'user1',text:'service'}
];
const d=exportData({personal_information:{user_id:1},chats:{list:[
 {type:'personal_chat',name:'Друг',messages},
 {type:'saved_messages',name:'Saved',messages},
 {type:'private_group',name:'Group',messages},
 {type:'personal_chat',name:'Ще друг',messages:[messages[1]]}
]}});
const rows=rankingRows(d);
assert.equal(rows.length,2);assert.equal(rows[0].total,3);assert.equal(rows[0].yours,2);assert.equal(rows[0].others,1);
const p=wordPeople(rows[0]);assert.equal(p[0].name,'Оля нова');
assert.deepEqual(topWords(p[0],STOPWORDS,3),[['кава',2],['чай',1]]);
assert.deepEqual(topWords(p[0],STOPWORDS,4),[['кава',2]]);
assert.deepEqual(topWords(p[1],STOPWORDS,3),[['привіт',2]]);
assert.equal(exportData({messages}).own,null);
assert.throws(()=>exportData({}));assert.throws(()=>exportData(null));
const same=exportData({messages:[{type:'message',from:'A',from_id:'user1',text:'test'},{type:'message',from:'A',from_id:'user2',text:'test'}]});
assert.equal(wordPeople(same.chats[0]).length,2);
assert.equal(csvValue('=1+1'),'"\'=1+1"');assert.equal(csvValue('a"b'),'"a""b"');
assert.ok(!html.includes('STOPWORDS_PLACEHOLDER'));
assert.ok(html.includes("connect-src 'none'"));
console.log('PASS: JavaScript syntax; chat totals and sender identity; excluded chat types; rich text; stopwords; minimum letters; Unicode; CSV escaping; invalid exports.');
assert.deepEqual(['цього',"don't",'should','этого','будет'].map(w=>STOPWORDS.has(w)),[true,true,true,true,true]);
const l10n=script.slice(script.indexOf('const TRANSLATIONS ='),script.indexOf('const staticText='));
const context={navigator:{language:'en-US'}};vm.createContext(context);vm.runInContext(l10n,context);
for(const lang of ['uk','en','ru']){vm.runInContext(`language='${lang}';if(!Object.values(TRANSLATIONS).every(v=>typeof v[language]==='string'&&v[language].length))throw Error('Missing translation');`,context);}
assert.equal(vm.runInContext("language='en';t('Відкрити JSON')",context),'Open JSON');
assert.equal(vm.runInContext("language='ru';t('Відкрити JSON')",context),'Открыть JSON');
assert.equal(vm.runInContext("language='uk';t('Відкрити JSON')",context),'Відкрити JSON');
assert.ok(!html.includes('linear-gradient'));
console.log('PASS: Three simultaneous language filters; complete translations; language switching; simplified design.');
