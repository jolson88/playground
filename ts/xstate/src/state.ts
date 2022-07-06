import { createMachine, interpret } from 'xstate';

/** @xstate-layout N4IgpgJg5mDOIC5QAkwBs0HsAEBZAhgMYAWAlgHZgB0AruRaQC6n5qkBekAxADIDyAcQCSAOUSgADplhNSmcuJAAPRAFoAnAAYqADgAsANgDMBzXvUB2AIwAmdXr0AaEAE81NndvUBWc1at6dsY2VgC+oc6oGDgEJBTUWFAwEELkvIJ8AKoAKopSMszyiioIqlYGFroG3joWekY25kbqNgbObgg63lTezbW+evqaRoHhkehYeERklFSJyXw0jOnCYkgg+bJF6yV6VNYeVg11Fi0tOm2uiAYGVJq+VjX29zo2deERIOSYEHCKUZNYjNqHQGMxWBxIHlpFsFDs1Op1FQQv11PpTDYQt52moTEYqEZvNZDJ5Gh5vGMQACYtN4nNMElIKloQU5HDQCUypodLpERZvNy9EdAnoLDjSlYLDYqOZzN5-AZHpoLEZKdSpnFZvNIItGCzYcUEZVvDYTUZJSZ1EYGjZxTYjJVlfo3jpzUZXVYdGqJjTNWB9YV2co1FZ1FYqjU6g0mi1Lh1VPVbg19L4Xfo9B9QkA */
const authMachine = createMachine(
  {
  context: { user: undefined },
  tsTypes: {} as import("./state.typegen").Typegen0,
  schema: {
    context: {} as { user?: string },
    events: {} as { type: "LOGIN"; user: string } | { type: "LOGOUT" },
  },
  id: "Hello Machine",
  initial: "uninitialized",
  states: {
    uninitialized: {
      on: {
        LOGIN: {
          actions: "sendTelemetry",
          target: "loggedIn",
        },
      },
    },
    loggedIn: {
      entry: "sayHello",
      on: {
        LOGOUT: {
          target: "loggedOut",
        },
      },
    },
    loggedOut: {
      entry: "sayGoodbye",
      on: {
        LOGIN: {
          actions: "sendTelemetry",
          target: "loggedIn",
        },
      },
    },
  },
},
  {
    actions: {
      sayHello: (context, event) => {
        context.user = event.user;
        console.log(`Hello, ${context.user}!`);
      },
      sayGoodbye: (context) => {
        console.log(`Goodbye, ${context.user}`);
      },
      sendTelemetry: (_context, event) => {
        console.log(`TELEMETRY: User ${event.user} logging in from Seattle, WA`);
      },
    }
  }
);

const authService = interpret(authMachine)
  .onTransition((state) => {
    console.log(`[[${state.value}]]`);
  })
  .onEvent((event) => {
    console.log(`<! ${event.type}`);
  });

authService.start();
authService.send({ type: 'LOGIN', user: 'Jason' });
authService.send({ type: 'LOGOUT' });
authService.send({ type: 'LOGIN', user: 'Skylar' });
// loggedIn state doesn't response to LOGIN events...
// So this should NOT trigger a new sayHello call or TELEMETRY call
authService.send({ type: 'LOGIN', user: 'Ignoramus' });
