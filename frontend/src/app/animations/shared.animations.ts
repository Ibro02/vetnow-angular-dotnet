import {
  trigger,
  transition,
  style,
  animate,
  query,
  stagger,
  state,
  keyframes,
} from '@angular/animations';

/** Fade In — for any component entering the DOM */
export const fadeIn = trigger('fadeIn', [
  transition(':enter', [
    style({ opacity: 0, transform: 'translateY(8px)' }),
    animate('300ms cubic-bezier(0.0, 0.0, 0.2, 1)',
      style({ opacity: 1, transform: 'translateY(0)' })
    ),
  ]),
]);

/** Scale In — for modals, popovers */
export const scaleIn = trigger('scaleIn', [
  transition(':enter', [
    style({ opacity: 0, transform: 'scale(0.92)' }),
    animate('250ms cubic-bezier(0.34, 1.56, 0.64, 1)',
      style({ opacity: 1, transform: 'scale(1)' })
    ),
  ]),
  transition(':leave', [
    animate('200ms cubic-bezier(0.4, 0, 1, 1)',
      style({ opacity: 0, transform: 'scale(0.95)' })
    ),
  ]),
]);

/** List Stagger — items appear one by one */
export const listStagger = trigger('listStagger', [
  transition('* => *', [
    query(':enter', [
      style({ opacity: 0, transform: 'translateY(15px)' }),
      stagger('60ms', [
        animate('350ms cubic-bezier(0.0, 0.0, 0.2, 1)',
          style({ opacity: 1, transform: 'translateY(0)' })
        ),
      ]),
    ], { optional: true }),
  ]),
]);

/** Slide Down — for dropdown menus, expandable sections */
export const slideDown = trigger('slideDown', [
  transition(':enter', [
    style({ height: 0, opacity: 0, overflow: 'hidden' }),
    animate('250ms cubic-bezier(0.0, 0.0, 0.2, 1)',
      style({ height: '*', opacity: 1 })
    ),
  ]),
  transition(':leave', [
    style({ overflow: 'hidden' }),
    animate('200ms cubic-bezier(0.4, 0, 1, 1)',
      style({ height: 0, opacity: 0 })
    ),
  ]),
]);

/** Expand / Collapse — for accordion panels */
export const expandCollapse = trigger('expandCollapse', [
  state('collapsed', style({ height: '0', opacity: 0, overflow: 'hidden' })),
  state('expanded', style({ height: '*', opacity: 1 })),
  transition('collapsed <=> expanded', [
    animate('300ms cubic-bezier(0.4, 0, 0.2, 1)'),
  ]),
]);

/** Pulse — attention-grab for new items */
export const pulse = trigger('pulse', [
  transition(':enter', [
    animate('600ms', keyframes([
      style({ transform: 'scale(1)', offset: 0 }),
      style({ transform: 'scale(1.04)', offset: 0.5 }),
      style({ transform: 'scale(1)', offset: 1 }),
    ])),
  ]),
]);

/** Shake — for form validation errors */
export const shake = trigger('shake', [
  transition('false => true', [
    animate('400ms', keyframes([
      style({ transform: 'translateX(0)', offset: 0 }),
      style({ transform: 'translateX(-6px)', offset: 0.15 }),
      style({ transform: 'translateX(5px)', offset: 0.3 }),
      style({ transform: 'translateX(-4px)', offset: 0.5 }),
      style({ transform: 'translateX(3px)', offset: 0.65 }),
      style({ transform: 'translateX(-2px)', offset: 0.8 }),
      style({ transform: 'translateX(0)', offset: 1 }),
    ])),
  ]),
]);
