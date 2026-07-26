"use strict";

const CONTROL = "/data/adb/modules/dugtx-docker-dev/scripts/control.sh";
let callbackId = 0;

function shell(command) {
  return new Promise((resolve, reject) => {
    if (!window.ksu || typeof ksu.exec !== "function") {
      reject(new Error("KernelSU WebUI API is unavailable"));
      return;
    }
    const name = `dockerCallback${++callbackId}`;
    window[name] = (code, stdout, stderr) => {
      delete window[name];
      if (code === 0) resolve(stdout || "");
      else reject(new Error((stderr || stdout || `exit ${code}`).trim()));
    };
    ksu.exec(command, name);
  });
}

function message(text, error = false) {
  const node = document.getElementById("message");
  node.textContent = text;
  node.style.color = error ? "#ff9aa4" : "#cce4ff";
  node.classList.add("visible");
  clearTimeout(message.timer);
  message.timer = setTimeout(() => node.classList.remove("visible"), 5000);
}

function setBusy(busy) {
  document.querySelectorAll("button").forEach(button => { button.disabled = busy; });
}

function parseConfig(text) {
  const config = {};
  text.split(/\r?\n/).forEach(line => {
    const index = line.indexOf("=");
    if (index > 0) config[line.slice(0, index)] = line.slice(index + 1);
  });
  return config;
}

async function refresh() {
  try {
    const output = await shell(`${CONTROL} status`);
    document.getElementById("status").textContent = output.trim() || "No status output";
    const config = parseConfig(output);
    if (config.CGROUP_MODE) document.getElementById("cgroup").value = config.CGROUP_MODE;
    if (config.NETWORK_MODE) document.getElementById("network").value = config.NETWORK_MODE;
    if (config.AUTO_START) document.getElementById("autostart").checked = config.AUTO_START === "1";
    if (config.DOCKER_IMAGE_SIZE) document.getElementById("size").value = config.DOCKER_IMAGE_SIZE.replace(/G$/, "");
  } catch (error) {
    document.getElementById("status").textContent = error.message;
    message(error.message, true);
  }
}

async function runAction(action) {
  setBusy(true);
  try {
    const output = await shell(`${CONTROL} ${action}`);
    message(output.trim() || `${action} completed`);
    await refresh();
  } catch (error) {
    message(error.message, true);
  } finally {
    setBusy(false);
  }
}

async function saveAndRestart() {
  const cgroup = document.getElementById("cgroup").value;
  const network = document.getElementById("network").value;
  const autoStart = document.getElementById("autostart").checked ? "1" : "0";
  setBusy(true);
  try {
    await shell(`${CONTROL} set CGROUP_MODE ${cgroup}`);
    await shell(`${CONTROL} set NETWORK_MODE ${network}`);
    await shell(`${CONTROL} set AUTO_START ${autoStart}`);
    await shell(`${CONTROL} apply`);
    message("配置已保存并应用 / Configuration applied");
    await refresh();
  } catch (error) {
    message(error.message, true);
  } finally {
    setBusy(false);
  }
}

async function resize() {
  const value = document.getElementById("size").value.trim();
  if (!/^\d+$/.test(value) || Number(value) < 2 || Number(value) > 512) {
    message("容量必须是 2–512 之间的整数", true);
    return;
  }
  setBusy(true);
  try {
    const output = await shell(`${CONTROL} resize ${value}G`);
    message(output.trim() || "扩容完成 / Resize complete");
    await refresh();
  } catch (error) {
    message(error.message, true);
  } finally {
    setBusy(false);
  }
}

document.getElementById("refresh").addEventListener("click", refresh);
document.querySelectorAll("[data-action]").forEach(button => {
  button.addEventListener("click", () => runAction(button.dataset.action));
});
document.getElementById("apply").addEventListener("click", saveAndRestart);
document.getElementById("resize").addEventListener("click", resize);
document.getElementById("logs").addEventListener("click", async () => {
  try {
    document.getElementById("logOutput").textContent = await shell(`${CONTROL} logs 160`);
  } catch (error) {
    document.getElementById("logOutput").textContent = error.message;
  }
});

refresh();
