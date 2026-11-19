// 3.9.7 (the person's decision): a new version of an installed skill waits for the person, and
// the request reaches every channel at once like the other requests (the page and the app in
// Extensions, the linked chats with Approve and Reject); the first answer closes the other
// copies and says where. The decision itself is the builder's (`ExtensionBuilder.decide`).
import { EventEmitter } from "node:events";
import type { SkillUpdateRequestInfo } from "@redgiant/protocol";

export type SkillDecision = "approve" | "reject";

export interface SkillUpdateRequests {
  on(event: "request", l: (ownerId: string, info: SkillUpdateRequestInfo) => void): this;
  on(
    event: "closed",
    l: (ownerId: string, proposalId: string, decision: SkillDecision, via: string) => void,
  ): this;
}

export class SkillUpdateRequests extends EventEmitter {
  /** The requests sent to the chats and still open, by proposal. */
  private readonly open = new Map<string, string>();

  constructor(
    private readonly decideFn: (
      ownerId: string,
      proposalId: string,
      decision: SkillDecision,
    ) => Promise<unknown>,
  ) {
    super();
  }

  /** A new version waits: every channel is asked. */
  request(ownerId: string, info: SkillUpdateRequestInfo): void {
    this.open.set(info.proposalId, ownerId);
    this.emit("request", ownerId, info);
  }

  /** The person's answer from a chat (`via`: telegram, discord…); false when already closed. */
  async decide(
    ownerId: string,
    proposalId: string,
    decision: SkillDecision,
    via: string,
  ): Promise<boolean> {
    if (this.open.get(proposalId) !== ownerId) return false;
    this.open.delete(proposalId);
    try {
      await this.decideFn(ownerId, proposalId, decision);
    } catch {
      return false;
    }
    this.emit("closed", ownerId, proposalId, decision, via);
    return true;
  }

  /** Decided in the page or the app: the chats' copies say so. */
  decidedElsewhere(ownerId: string, proposalId: string, decision: SkillDecision, via: string) {
    if (this.open.get(proposalId) !== ownerId) return;
    this.open.delete(proposalId);
    this.emit("closed", ownerId, proposalId, decision, via);
  }
}
